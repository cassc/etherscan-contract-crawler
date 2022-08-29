//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface USDC {
    function transfer(address dst, uint amt) external returns (bool);

    function transferFrom(address src, address dst, uint amt) external returns (bool);

    function balanceOf(address src) external view returns (uint);
}

contract ApeiroPage is ERC1155, Ownable {
    uint256 private _price = 1000 * (10 ** 6); //1000 USDC
    uint256 private _totalMinted = 0;
    uint256 private _canMintInBatch = 0;
    uint256 private _mintedInBatch = 0;
    uint256 private _maxMint = 0;
    mapping(address => bool) private whitelistedAddresses;
    string public cid = "QmPc683wwnpoNe8pSDk91oHhsT9sihxYEgEPzEM8o9eVfB";
    USDC public usdc;

    constructor() ERC1155("") Ownable(){
        usdc = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    //in the function below include the CID of the JSON folder on IPFS
    // TODO: Change the ipfs link to final json folder after uploading images and json
    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/", cid, "/image_",
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

    function updateCid(string memory _cid) public onlyOwner {
        cid = _cid;
    }

    function enableMint(uint256 count) public onlyOwner {
        if (_maxMint != 0) {
            require(_totalMinted < _maxMint, "Max mint exceeded");
            require(_totalMinted + count <= _maxMint, "This will exceed max allowed mint");
        }
        _canMintInBatch = count;
        _mintedInBatch = 0;
    }

    function mint(uint256 _amountInUsdc) external {
        uint256 alreadyMinted = _mintedInBatch;
        uint256 mintId = _totalMinted + 1;
        require(alreadyMinted < _canMintInBatch, "Sold out");
        require(_price <= _amountInUsdc, "USDC value sent is not correct");
        require(whitelistedAddresses[msg.sender], "Not in whitelist, can't mint");
        // Transfer the USDC to contract
        bool success = usdc.transferFrom(msg.sender, address(this), _amountInUsdc);
        require(success, "Buy failed");

        // mint the nft and send to buyer
        _mint(msg.sender, mintId, 1, "");

        alreadyMinted++;
        _totalMinted = mintId;
        _mintedInBatch = alreadyMinted;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function setMaxMint(uint256 maxAmt) public onlyOwner {
        _maxMint = maxAmt;
    }

    function totalMinted() public view virtual returns (uint256) {
        return _totalMinted;
    }

    function canMintInBatch() public view virtual returns (uint256) {
        return _canMintInBatch;
    }

    function mintedInBatch() public view virtual returns (uint256) {
        return _mintedInBatch;
    }

    function maxMint() public view virtual returns (uint256) {
        return _maxMint;
    }

    function getPrice() public view virtual returns (uint256) {
        return _price;
    }

    function withdraw() external onlyOwner {
        usdc.transfer(owner(), usdc.balanceOf(address(this)));
    }

    function availableForWithdrawl() public view virtual returns (uint256){
        return usdc.balanceOf(address(this));
    }

    function isWhitelisted(address addr) public view virtual returns (bool) {
        return whitelistedAddresses[addr];
    }

    function whitelistAddresses(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = false;
        }
    }

}