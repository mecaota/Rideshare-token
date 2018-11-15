pragma solidity 0.4.25;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721MetadataMintable.sol";

/**
 * @title ERC721FullMock
 * This mock just provides a public mint and burn functions for testing purposes,
 * and a public setter for metadata URI
 */
contract ERC721FullMock 
is ERC721Full, ERC721MetadataMintable {
    
    constructor(string name, string symbol) public
    ERC721Full(name, symbol)
    {}
    
    function mint(uint256 tokenId) public onlyMinter returns (bool) {
        super._mint(msg.sender, tokenId);
        return true;
    }
        
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        super._burn(ownerOf(tokenId), tokenId);
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
}