pragma solidity 0.4.25;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
//import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/roles/MinterRole.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721MetadataMintable.sol";
//import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract RideShareToken is ERC721Full, MinterRole, Ownable {
    struct Spot{
        string name;
        int32 latitude;
        int32 longitude;
    }
    
    struct Demand{
        bool available;
        uint cost;
        uint reg_date;
        uint est_date;
        uint passengers;
        Spot dept;
        Spot arrv;
    }
    
    mapping(uint=>Demand) private demands;
    uint256 private nextTokenId = 0;
    
    constructor() public ERC721Full("RideShareDemand", "RSD") {}
    
    function _generateTokenId() private returns(uint256){
        nextTokenId = nextTokenId.add(1);
        return nextTokenId;
    }
    
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    function setTokenURI(uint256 tokenId, string uri) public {
        _setTokenURI(tokenId, uri);
    }
    
    function removeTokenFrom(address from, uint256 tokenId) public {
        _removeTokenFrom(from, tokenId);
    }
    
    //onlyminterは削除
    function mint (
        uint _cost,
        uint _est_date,
        uint _passengers,
        string dept_name,
        int32 dept_lat,
        int32 dept_lon,
        string arrv_name,
        int32 arrv_lat,
        int32 arrv_lon
        )
        public
        payable
        returns (bool)
        {
            uint256 _tokenId = _generateTokenId();
            super._mint(msg.sender, _tokenId);
            updateToken (
                _tokenId,
                _cost,
                _est_date,
                _passengers,
                dept_name,
                dept_lat,
                dept_lon,
                arrv_name,
                arrv_lat,
                arrv_lon
                );
            return true;
        }
    
    function burn(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        super._burn(ownerOf(_tokenId), _tokenId);
        delete demands[_tokenId];
    }
    
    function updateToken (
        uint _tokenId,
        uint _cost,
        uint _est_date,
        uint _passengers,
        string dept_name,
        int32 dept_lat,
        int32 dept_lon,
        string arrv_name,
        int32 arrv_lat,
        int32 arrv_lon
        )
        public
        {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        demands[_tokenId] = Demand({
            available:true,
            cost:_cost,
            reg_date:now,
            est_date:_est_date,
            passengers:_passengers,
            dept:Spot({
                name:dept_name,
                latitude:dept_lat,
                longitude:dept_lon
            }),
            arrv:Spot({
                name:arrv_name,
                latitude:arrv_lat,
                longitude:arrv_lon
            })
        });
    }
}
