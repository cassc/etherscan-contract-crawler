// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 504 - IYKYK / KMWTW
// www.504.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nft504 is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    IERC20 public immutable BIGSB;
    uint256 internal constant START_PRICE = 2000 ether;
    uint256 internal constant MAX_SUPPLY = 5040;
    uint256 public minted;
    mapping(address => uint256) public lastMintTimestamp;
    string internal bUri = "https://data.504.xyz/nft/";
    bool public isMintingDisabled;
    
    constructor(IERC20 bigSBAddress, address receiver) ERC721("504.xyz", "504") {
        BIGSB = bigSBAddress;
        for(uint256 i = 1; i <= 10; i++){
            _mint(receiver, i);
        }
        transferOwnership(receiver);
        minted = 10;
    }

    function _baseURI() internal view override returns (string memory) {
        return bUri;
    }

    function baseTokenURI() public view returns (string memory) {
        return bUri;
    }

    function editBaseUri(string memory newUri) external onlyOwner{
        bUri = newUri;
    }

    function setStatus(bool disableMinting) external onlyOwner{
        isMintingDisabled = disableMinting;
    }
    
    function actualPrice() external view returns(uint256){
        return _actualPrice(minted);
    }

    function _actualPrice(uint256 _minted) internal pure returns(uint256){
        return START_PRICE + _minted * 1 ether;
    }

    function mint() external {
        require(!isMintingDisabled, "Mint: Minting disabled");
        require((lastMintTimestamp[msg.sender]+24 hours)<block.timestamp, "Mint: Daily mint limit exceeded");
        lastMintTimestamp[msg.sender] = block.timestamp;
        uint256 _minted = minted+1;
        require(_minted<=MAX_SUPPLY, "Mint: Maximum supply reached");
        minted++;
        BIGSB.transferFrom(msg.sender, address(this), _actualPrice(_minted-1));
        _mint(msg.sender, _minted);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrowTokens() external onlyOwner{
        uint256 amount = BIGSB.balanceOf(address(this));
        BIGSB.transfer(msg.sender, amount);
    }
}

// 504 - IYKYK / KMWTW
// www.504.xyz