// SPDX-License-Identifier: MIT
//___                    _                                ___                      _
//| _ \  _  _    _ _     | |__   __ _     ___     ___     | _ \  __ _    _ _     __| |   __ _
//|  _/ | +| |  | ' \    | / /  / _` |   (_-<    (_-<     |  _/ / _` |  | ' \   / _` |  / _` |
//_|_|_   \_,_|  |_||_|   |_\_\  \__,_|   /__/_   /__/_   _|_|_  \__,_|  |_||_|  \__,_|  \__,_|
//_| """ |_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_| """ |_|"""""|_|"""""|_|"""""|_|"""""|
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣶⣶⣦⡀⠀⠀⢀⣀⡀⢤⣤⡤⠀⣀⣀⠀⠀⢀⣠⣴⣶⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⠶⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠉⠒⢾⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⣤⣄⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⢀⣾⢇⣿⣷⡀⠀⠀⢀⣴⢦⠈⢿⣿⣿⣿⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣐⣿⣿⡟⠀⠀⠀⣀⣠⣤⣶⣿⡿⠘⢿⣿⣷⣿⣶⣿⠏⠸⣿⣾⣿⣿⣿⣿⣿⡆⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⢀⣀⣀⠀⠀⠀⠛⣿⣿⠉⠉⠉⠉⠛⠲⠶⣶⣶⣦⣠⣶⣶⠶⠒⢲⣶⣦⣴⣶⡶⠶⣶⣶⣶⣿⢧⣤⣄⢰⣿⡇⠀⠀⠀⠀⠀
//⠀⠀⣶⣆⢸⣿⣿⠀⠀⠀⠀⠈⡍⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣏⠀⠀⠀⠀⢙⡿⠿⠋⠀⠀⢹⡿⠛⠁⢸⣿⣿⣾⣿⣧⣤⡄⠀⠀⠀
//⠀⠀⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠈⣽⠟⠁⠠⢤⣤⣤⠤⣷⠀⠀⠀⠀⠈⣆⠀⠀⠀⢿⣿⣿⣿⣿⣿⣷⡄⠀⠀
//⠀⣾⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⢠⣤⡄⣀⣈⣁⣠⠋⠀⠀⠀⠀⢠⣿⡆⠀⠀⢸⣿⣿⣿⣿⣿⡟⠁⠀⠀
//⠀⠹⣿⣿⣿⣿⣿⡇⠀⠀⢀⣾⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣬⣉⣉⡀⠀⠀⠀⠀⢠⣿⣿⣷⡄⠀⠀⢻⣿⣿⣿⣿⡇⠀⠀⠀
//⠀⠀⢹⣿⣿⣿⣿⡁⠀⢠⣾⣿⣿⣿⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠉⠀⠀⢀⣤⣶⣿⣿⣿⣿⣿⣄⡀⣼⣿⣿⣿⣿⡇⠀⠀⠀
//⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣤⣄⣀⣀⣀⣀⣠⣤⣴⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
//⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠻⠛⠛⠛⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
//⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
//⠀⠀⠀⠀⠀⠙⠿⠿⠿⣿⣿⣿⣿⣿⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣯⠙⠛⠛⠿⠿⠟⠛⠁⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PunkAssPanda is Ownable, ERC721Enumerable {
    using Strings for uint256;

    bool private mintStartEnabled = false;
    bool private revealed = false;
    string private  baseUrl;
    string private boxUrl;
    mapping (address => uint256) private walletsMint;

    uint256 private constant MAX_SUPPLY = 1010;
    uint256 private constant MAX_MINT = 10;
    uint256 private constant MINT_PRICE = 0.003 ether;
    uint256 private constant FREE_MINT_NUM = 2;

    constructor() ERC721("PunkAssPanda", "PAP") {}

    function publicMint(uint256 mintNum) external payable{
        require(mintStartEnabled, "Please wait for the DEGEN HOURS!");
        require(mintNum <= MAX_MINT, "Only a maximum of 10 NFTs can be minted at a time");
        require(totalSupply() + mintNum <= MAX_SUPPLY, "Not enough supply to mint");
        if(walletsMint[msg.sender] >= FREE_MINT_NUM){
            require(mintNum * MINT_PRICE <= msg.value, "Make sure to have enough eth in your wallet");
            walletsMint[msg.sender] += mintNum;
            _mintPanda(msg.sender, mintNum);
        }
        else{
            if(mintNum < FREE_MINT_NUM){
                mintNum = FREE_MINT_NUM;
            }
            require(msg.value >= (mintNum - FREE_MINT_NUM) * MINT_PRICE,"Make sure to have enough eth in your wallet");
            walletsMint[msg.sender] += mintNum;
            _mintPanda(msg.sender, mintNum);
        }
    }
    function _mintPanda(address _address,uint256 mintNum) internal {
        for (uint256 i = 0; i < mintNum; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_address, mintIndex);
            }
        }
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return string(abi.encodePacked(boxUrl, tokenId.toString(), ".json"));
        }
        return string(abi.encodePacked(baseUrl, tokenId.toString(), ".json"));
    }


    function setMintStartEnabled() public onlyOwner {
        mintStartEnabled = !mintStartEnabled;
    }
    function setRevealed() public onlyOwner {
        revealed = !revealed;
    }
    function setBaseUrl(string memory url) public onlyOwner {
        baseUrl = url;
    }
    function setBoxUrl(string memory url) public onlyOwner {
        boxUrl = url;
    }


    function getMintStartEnabled() public view returns (bool){
        return mintStartEnabled;
    }
    function getRevealed() public view returns (bool){
        return revealed;
    }
    function getBaseUrl() public view returns (string memory){
        return baseUrl;
    }
    function getBoxUrl() external view returns (string memory) {
        return boxUrl;
    }
    function getWalletsMint(address _address) external view returns (uint256){
        return walletsMint[_address];
    }
    function getFreeMintNum() external pure returns(uint256) {
        return FREE_MINT_NUM;
    }
    function getMaxSupply() external pure returns (uint256){
        return MAX_SUPPLY;
    }
    function getMaxMint() external pure returns (uint256){
        return MAX_MINT;
    }
    function getMintPrice() external pure returns (uint256){
        return MINT_PRICE;
    }


    function airdropNFT(address to, uint256 mintNum) external onlyOwner {
        _mintPanda(to, mintNum);
    }
    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}