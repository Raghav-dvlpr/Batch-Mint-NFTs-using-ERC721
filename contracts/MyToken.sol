// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract MyToken is ERC721, Pausable, Ownable, ERC721Burnable {
     struct Royalties{
        address account;
        uint percentage;
    }

    // storing the royalty details of a token
    mapping(uint256 => Royalties) private _royalties;
    
    event RoyaltyAdded(uint256 indexed tokenId, address indexed account, uint256 percentage);

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(uint256 => string) private _tokenURIs;


    constructor() ERC721("MyToken", "MTK") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.gateway.pinata.ipfs.com/";
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(_exists(_tokenId), "ERC721Metadata: URI set of nonexistent token");
        
        bytes memory tempBytes = bytes(_tokenURI);
        if(tempBytes.length > 0) _tokenURIs[_tokenId] = _tokenURI;
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function batchMint(address _to,
            uint256[] memory _tokenId,
            string[] memory IPFSHash,
            Royalties calldata _royalties) public  onlyOwner {
            require(_tokenId.length == IPFSHash.length,"");
            for (uint i = 0; i < _tokenId.length; i++){
                _mint(_to, _tokenId[i]);
                _setTokenURI(_tokenId[i], IPFSHash[i]);
                _setRoyalties(_tokenId[i], _royalties);
            }
    }

    function updateRoylaites(uint256 _tokenId, Royalties calldata _royalties) public onlyOwner{
        _setRoyalties(_tokenId, _royalties);
    }


    function _setRoyalties(uint256 _tokenId, Royalties calldata royalties) internal virtual {
        // calculated for 10000 
        require(royalties.percentage <= 5000, "exceeds royalty collective max value of Fifty percent"); // 5000/10000 = 50 % 
        // require(royalties.percentage >= 500, "subceed royalty collective min value of five percent");// 500/10000 = 5 %
        
        if(royalties.account != address(0)){
            _royalties[_tokenId] = royalties;
            emit RoyaltyAdded(_tokenId, royalties.account, royalties.percentage);
        }
    }
    
    function royaltyInfo(uint256 _tokenId,uint256 _salePrice) external view returns (address receiver,uint256 royaltyAmount){
        require(_exists(_tokenId), "query for non nonexistent token");
        
        royaltyAmount = (_salePrice * _royalties[_tokenId].percentage) / 10000;
        receiver = _royalties[_tokenId].account;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function supportsInterface(bytes4 interfaceId) public view override returns (bool)
    {
        // add support to EIP-2981: NFT Royalty Standard
        if(interfaceId == _INTERFACE_ID_ERC2981){
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
    uint256[48] private __gap;
}
