pragma solidity 0.4.25;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721MetadataMintable.sol";

/**
 * @title ERC721FullMock
 * This mock just provides a public mint and burn functions for testing purposes,
 * and a public setter for metadata URI
 */
contract RideshareToken is ERC721Full, ERC721MetadataMintable {
    
    struct Spot{
        string name;
        int32 latitude;
        int32 longitude;
    }
    
    struct Demand{
        bool available;
        uint cost;
        uint upd_date;
        uint est_date;
        uint passengers;
        Spot dept;
        Spot arrv;
    }
    
    mapping(uint=>Demand) private demands;
    uint256 private nextTokenId = 0;
    
    constructor(string name, string symbol)
    public
    ERC721Full(name, symbol)
    {}

    function _generateTokenId() private returns(uint256) {
        nextTokenId = nextTokenId.add(1);
        return nextTokenId;
    }
    
    function mint(
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
        onlyMinter
        returns (bool)
        {
        uint256 tokenId = _generateTokenId();
        super._mint(msg.sender, tokenId);
        _updateToken (
                true,
                tokenId,
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
        
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        super._burn(ownerOf(tokenId), tokenId);
        delete demands[tokenId];
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

    function _updateToken (
        bool available,
        uint tokenId,
        uint cost,
        uint est_date,
        uint passengers,
        string dept_name,
        int32 dept_lat,
        int32 dept_lon,
        string arrv_name,
        int32 arrv_lat,
        int32 arrv_lon
        )
        private
        {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        demands[tokenId].upd_date = block.timestamp;
        demands[tokenId].available = available;
        
        if(cost != 0){
            demands[tokenId].cost = cost;
        }
        
        if(est_date != 0){
            demands[tokenId].est_date = est_date;
        }
        
        if(passengers != 0){
            demands[tokenId].passengers = passengers;
        }
        
        if(bytes(dept_name).length!=0 && dept_lat!=0 && dept_lon!=0){
            demands[tokenId].dept.name = dept_name;
            demands[tokenId].dept.latitude = dept_lat;
            demands[tokenId].dept.longitude = dept_lon;
        }
        
        if(bytes(arrv_name).length!=0 && arrv_lat!=0 && arrv_lon!=0){
            demands[tokenId].arrv.name = arrv_name;
            demands[tokenId].arrv.latitude = arrv_lat;
            demands[tokenId].arrv.longitude = arrv_lon;
        }
    }
}