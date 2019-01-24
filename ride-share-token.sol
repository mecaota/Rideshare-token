pragma solidity ^0.5.2;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol";
      
/**
 * @title ERC721FullMock
 * This mock just provides a public mint and burn functions for testing purposes,
 * and a public setter for metadata URI
 */
contract RideshareDemand is ERC721Enumerable{
    
    struct Spot{
        string name;
        int32 latitude;
        int32 longitude;
    }
    
    struct Demand{
        address purchaser;
        uint256 item_id;
        uint32 price;
        uint256 est_date;
        Spot dept;
        Spot arrv;
    }
    
    event BoughtTicket(address indexed purchaser, uint256 price);
    event ChangeDemand(uint indexed demandId, string changed);
    //event TicketAuthorized(address indexed purchaser, address indexed minter, uint indexed demandId);
    
    mapping(uint256=>Demand) private _demands; // token_id to demand(=item_id) struct
    mapping(uint256=>uint256[]) private _itemid2demand; // item_id to demand
    
    uint256 private _nextTokenId = 0;

    function _generateTokenId() private returns(uint256) {
        _nextTokenId = _nextTokenId.add(1);
        return _nextTokenId;
    }
    
    function mintDemands(
        uint8 passengers,
        uint32 price,
        uint256 est_date,
        string memory dept_name,
        int32 dept_latitude,
        int32 dept_longitude,
        string memory arrv_name,
        int32 arrv_latitude,
        int32 arrv_longitude
        )
        public
        returns (bool)
        {   
            if(balanceOf(msg.sender) > 0){
                for(uint256 i = 0; i < balanceOf(msg.sender); i++){
                    require(_isMyTicket(tokenOfOwnerByIndex(msg.sender, i)));
                }
            }
            uint256 item_id = 0;
            for(uint i=0; i<passengers; i++){
                uint256 demand_id = _generateTokenId();
                super._mint(msg.sender, demand_id);
                if(i==0){
                    item_id = demand_id;
                }
                _itemid2demand[item_id].push(demand_id);
            }
            _updateDemandToken(
                    item_id,
                    price,
                    est_date,
                    dept_name,
                    dept_latitude,
                    dept_longitude,
                    arrv_name,
                    arrv_latitude,
                    arrv_longitude
                    );
            return true;
        }
        
    function burn(uint256 demand_id) public {
        require(_isApprovedOrOwner(msg.sender, demand_id));
        super._burn(msg.sender, demand_id);
        delete _demands[demand_id];
    }
        
    function burnMintedDemand() public {
        for(uint256 i = 0; i < balanceOf(msg.sender); i++){
            uint256 demand_id = tokenOfOwnerByIndex(msg.sender, i);
            require(_isApprovedOrOwner(msg.sender, demand_id));
            if(!_isMyTicket(demand_id)){
                burn(demand_id);
            }
        }
    }
    
    // If purchaser is msg.sender, return true
    function _isMyTicket(uint256 demand_id) private view returns(bool){
        return (_demands[demand_id].purchaser==msg.sender);
    }
    
    // If purchaser is not null, return true
    function _isPurchesed(uint256 demand_id) private view returns(bool){
        return (_demands[demand_id].purchaser!=address(0));
    }
    
    function approveAllMintedTickets() public {
        for(uint256 i = 0; i < balanceOf(msg.sender); i++){
            uint256 demand_id = tokenOfOwnerByIndex(msg.sender, i);
            require(_isApprovedOrOwner(msg.sender, demand_id));
            if(!_isMyTicket(demand_id) && !_isPurchesed(demand_id)){
                address purchaser = _demands[demand_id].purchaser;
                approve(purchaser, demand_id);
            }
        }
    }
    
    function buyTicket(uint256 demand_id) public{
        require(!_isPurchesed(demand_id));
        require(ownerOf(demand_id) != msg.sender);
        _demands[demand_id].purchaser = msg.sender;
    }
    
    function getDemandInfo(uint256 demand_id)
        public
        view
        returns(
            bool,
            bool,
            uint256,
            uint32,
            uint256,
            string memory,
            int32,
            int32,
            string memory,
            int32,
            int32
        ){
        Demand memory demand = _demands[demand_id];
        return(
            _isMyTicket(demand_id),
            _isPurchesed(demand_id),
            demand.item_id,
            demand.price,
            demand.est_date,
            demand.dept.name,
            demand.dept.latitude,
            demand.dept.longitude,
            demand.arrv.name,
            demand.arrv.latitude,
            demand.arrv.longitude
            );
    }
    
    function _updateDemandToken (
        uint256 item_id,
        uint32 price,
        uint256 est_date,
        string memory dept_name,
        int32 dept_lat,
        int32 dept_lon,
        string memory arrv_name,
        int32 arrv_lat,
        int32 arrv_lon
    )
    private
    {
        for(uint i=0; i< balanceOf(msg.sender); i++){
            uint256 demand_id = tokenOfOwnerByIndex(msg.sender, i);
            require(super._isApprovedOrOwner(msg.sender, demand_id));
            _demands[demand_id].item_id = item_id;
            
            if(price != 0){
                _demands[demand_id].price = price;
                emit ChangeDemand(demand_id, "change price");
            }
            
            if(est_date != 0){
                _demands[demand_id].est_date = est_date;
                emit ChangeDemand(demand_id, "changed estimated time");
            }
            
            if(bytes(dept_name).length!=0 && dept_lat!=0 && dept_lon!=0){
                _demands[demand_id].dept.name = dept_name;
                _demands[demand_id].dept.latitude = dept_lat;
                _demands[demand_id].dept.longitude = dept_lon;
                emit ChangeDemand(demand_id, "changed departure spot");
            }
            
            if(bytes(arrv_name).length!=0 && arrv_lat!=0 && arrv_lon!=0){
                _demands[demand_id].arrv.name = arrv_name;
                _demands[demand_id].arrv.latitude = arrv_lat;
                _demands[demand_id].arrv.longitude = arrv_lon;
                emit ChangeDemand(demand_id, "changed arrival spot");
            }
        }
    }
}