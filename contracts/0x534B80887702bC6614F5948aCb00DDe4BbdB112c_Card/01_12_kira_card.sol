// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//import ERC1155
import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

contract Card is ERC1155, Ownable {

    uint256 tokenId = 1;
    string tokenUri = "https://kira-nft-data.s3.amazonaws.com/card/jsons/0";
    mapping(address => bool) public minter;
    bool public transferEnabled;
    uint8 public maxPerWallet = 1;

    modifier onlyMinter() {
        require(minter[msg.sender], "Caller is not a minter");
        _;
    }

    constructor() ERC1155("Card") {}

    function setMaxPerWallet(uint8 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function flipTransferEnabled() external onlyOwner {
        transferEnabled = !transferEnabled;
    }

    function setURI(string memory _uri) public onlyOwner {
        tokenUri = _uri;
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }

    function addMinter(address _minter) public onlyOwner {
        minter[_minter] = true;
    }

    function removeMinter(address _minter) public onlyOwner {
        minter[_minter] = false;
    }

    // Minting
    function mint(address to, uint8 amount) public onlyMinter {
        if (balanceOf(to, tokenId) + amount <= maxPerWallet) {
            _mint(to, tokenId, amount, "");
        }
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _mint(to, tokenId, amount, "");
    }

    // disable transfers
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        require(from == address(0) || transferEnabled, "Transfers are disabled");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setApprovalForAll(address, bool) public virtual override {
        revert("Not allowed");
    }

    function isApprovedForAll(address, address)
        public
        pure
        override
        returns (bool)
    {
        return false;
    }

    function saveTokens(IERC20 tokenAddress, uint256 amount) external onlyOwner() {
        SafeERC20.safeTransfer(tokenAddress, owner(), amount == 0 ? tokenAddress.balanceOf(address(this)) : amount);
    }
    
    function saveETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}