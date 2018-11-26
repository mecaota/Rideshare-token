pragma solidity 0.4.24;

import "./ERC721Enumerable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/payment/PullPayment.sol";

/**
 * @title ERC721FullMock
 * This mock just provides a public mint and burn functions for testing purposes,
 * and a public setter for metadata URI
 */
contract RideshareDemand is ERC721Enumerable, PullPayment{
    
    struct Spot{
        string name;
        int32 latitude;
        int32 longitude;
    }
    
    struct Demand{
        address minter;
        uint32 price;
        uint upd_date;
        uint est_date;
        uint8 passengers;
        Spot dept;
        Spot arrv;
    }
    
    struct Ticket{
        address purchaser;
        address minter;
        uint256 mint_date;
        uint256 demandId;
        uint32 price;
    }
    
    event BoughtTicket(address indexed purchaser, uint256 price);
    event ChangeDemand(uint indexed demandId, string changed);
    event TicketAuthorized(address indexed purchaser, address indexed minter, uint indexed demandId);
    
    mapping(uint256=>Demand) private _demands;
    mapping(uint256=>Ticket) private _tickets;
    mapping(uint256=>uint256) ticket2demand;
    
    uint256 private _nextTokenId = 0;
    
    constructor() public {}

    function _generateTokenId() private returns(uint256) {
        _nextTokenId = _nextTokenId.add(1);
        return _nextTokenId;
    }
    
    function mint_demand(
        uint32 price,
        uint256 est_date,
        uint8 passengers,
        string dept_name,
        int32 dept_lat,
        int32 dept_lon,
        string arrv_name,
        int32 arrv_lat,
        int32 arrv_lon
        )
        public
        returns (uint256)
        {
        uint256 demandId = _generateTokenId();
        super._mint(msg.sender, demandId);
        _updateDemandToken (
                demandId,
                price,
                est_date,
                passengers,
                dept_name,
                dept_lat,
                dept_lon,
                arrv_name,
                arrv_lat,
                arrv_lon
                );
        return demandId;
    }
    
    function mint_ticket(
        address purchaser,
        uint256 demandId,
        uint32 price
        )
        public
        returns (uint256)
        {
        address minter = ownerOf(demandId);
        require(minter != address(0));
        uint256 ticketId = _generateTokenId();
        super._mint(minter, ticketId);
        ticket2demand[ticketId] = demandId;
        _tickets[ticketId].purchaser = purchaser;
        _tickets[ticketId].minter = msg.sender;
        _tickets[ticketId].mint_date = block.timestamp;
        _tickets[ticketId].demandId = demandId;
        _tickets[ticketId].price = price;
        return ticketId;
    }
        
    function burn(uint256 demandId) public {
        require(_isApprovedOrOwner(msg.sender, demandId));
        super._burn(ownerOf(demandId), demandId);
        delete _demands[demandId];
    }
    
    function buyTicket(uint256 demandId) public payable returns(uint256){
        require(_demands[demandId].passengers > 0);
        address minter = ownerOf(demandId);
        require(minter != address(0));
        uint32 price = _demands[demandId].price;
        if(price>0){
            require(price == msg.value);
            _asyncTransfer(minter, price);
        }
        _demands[demandId].passengers--;
        uint256 ticketId = mint_ticket(msg.sender, demandId, price);
        emit BoughtTicket(msg.sender, price);
        return ticketId;
    }
    
    // 乗員譲渡用相手側
    function transferTicket(uint256 ticketId, address from_address) public returns(bool){
        address purchaser = ownerOf(ticketId);
        require(purchaser != address(0));
        require(purchaser != address(this));
        require(from_address == getApproved(ticketId));
        require(msg.sender == _tickets[ticketId].minter);
        safeTransferFrom(purchaser, msg.sender, ticketId);
        return true;
    }
    
    // 運転手改札用
    function takeTicket(uint256 ticketId) public returns(bool){
        address purchaser = ownerOf(ticketId);
        require(purchaser != address(0));
        require(purchaser != address(this));
        require(msg.sender == getApproved(ticketId));
        require(msg.sender == _tickets[ticketId].minter);
        uint256 demandId = _tickets[ticketId].demandId;
        require(ticket2demand[ticketId] == demandId);
        safeTransferFrom(purchaser, msg.sender, ticketId);
        super._burn(msg.sender, ticketId);
        delete _tickets[ticketId];
        delete ticket2demand[ticketId];
        emit TicketAuthorized(purchaser, msg.sender, demandId);
        return true;
    }
    
    function getDemandInfo(uint256 demandId)
        public
        view
        returns(
            uint256,
            address,
            uint32,
            uint256,
            uint256,
            uint8,
            string,
            int32,
            int32,
            string,
            int32,
            int32
        ){
        Demand memory demand = _demands[demandId];
        require(demand.upd_date != 0);
        return(
            demandId,
            demand.minter,
            demand.price,
            demand.upd_date,
            demand.est_date,
            demand.passengers,
            demand.dept.name,
            demand.dept.latitude,
            demand.dept.longitude,
            demand.arrv.name,
            demand.arrv.latitude,
            demand.arrv.longitude
            );
    }
    
    function getTicketInfo(uint256 ticketId)
        public
        view
        returns(
            uint256,
            uint256,
            uint256,
            uint32,
            address
        ){
        Ticket memory ticket = _tickets[ticketId];
        require(ticket.demandId != 0);
        require(_isApprovedOrOwner(msg.sender, ticketId) || ticket.minter==msg.sender);
        return(ticketId, ticket.mint_date, ticket.demandId, ticket.price, ticket.minter);
    }
    
    function changeTicketPrice(uint256 ticketId, uint32 price) public returns(bool){
        require(_isApprovedOrOwner(msg.sender, ticketId));
        _tickets[ticketId].price = price;
        return true;
    }
    
    function changeDept_spot(uint256 demandId, string name, int32 latitude, int32 longitude) public returns(bool){
        _updateDemandToken (demandId, 0, 0, 0, name, latitude, longitude, "", 0, 0);
        emit ChangeDemand(demandId, "changed departure spot");
        return true;
    }
    
    function changeArrv_spot(uint256 demandId, string name, int32 latitude, int32 longitude) public returns(bool){
        _updateDemandToken (demandId, 0, 0, 0, "", 0, 0, name, latitude, longitude);
        emit ChangeDemand(demandId, "changed arrival spot");
        return true;
    }
    
    function changeEst_date(uint256 demandId, uint256 est_date) public returns(bool){
        _updateDemandToken (demandId, 0, est_date, 0, "", 0, 0, "", 0, 0);
        emit ChangeDemand(demandId, "changed estimated time");
        return true;
    }
    
    
    function addremovePassengers(uint256 demandId, int8 change_passengers) public returns(bool){
        int8 passengers = change_passengers + int8(_demands[demandId].passengers);
        require(passengers > 0);
        _updateDemandToken (demandId, 0, 0, uint8(passengers), "", 0, 0, "", 0, 0);
        emit ChangeDemand(demandId, "changed passengers");
        return true;
    }
    
    function changeDemandPrice(uint256 demandId, uint32 price) public returns(bool){
        _updateDemandToken (demandId, price, 0, 0, "", 0, 0, "", 0, 0);
        emit ChangeDemand(demandId, "change price");
        return true;
    }

    function _updateDemandToken (
        uint256 demandId,
        uint32 price,
        uint256 est_date,
        uint8 passengers,
        string dept_name,
        int32 dept_lat,
        int32 dept_lon,
        string arrv_name,
        int32 arrv_lat,
        int32 arrv_lon
        )
        private
        {
        require(_isApprovedOrOwner(msg.sender, demandId));
        _demands[demandId].upd_date = block.timestamp;
        
        if(price != 0){
            _demands[demandId].price = price;
        }
        
        if(est_date != 0){
            _demands[demandId].est_date = est_date;
        }
        
        if(passengers != 0){
            _demands[demandId].passengers = passengers;
        }
        
        if(bytes(dept_name).length!=0 && dept_lat!=0 && dept_lon!=0){
            _demands[demandId].dept.name = dept_name;
            _demands[demandId].dept.latitude = dept_lat;
            _demands[demandId].dept.longitude = dept_lon;
        }
        
        if(bytes(arrv_name).length!=0 && arrv_lat!=0 && arrv_lon!=0){
            _demands[demandId].arrv.name = arrv_name;
            _demands[demandId].arrv.latitude = arrv_lat;
            _demands[demandId].arrv.longitude = arrv_lon;
        }
    }
}