// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PatriotNFT is ERC721, Ownable{
    uint256 public mintPrice;
    uint256 public mintPriceZero;
    uint256 public publicMintPrice;
    uint256 public maxSupply;
    uint256 public totalSupply;
    uint256 public maxPerWallet;
    bool exists;
    bool public isPublicMintEnabled;
    string internal baseTokenUri = "https://gateway.pinata.cloud/ipfs/QmUKq8mjgAw728r4VAnCqxYu8qjnCVK6XmJ5pth7qfD1RN";
    address payable private devAddress;
    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public publicWalletMints;
    address[] private whitelistedAddresses;
    address[] private freeMintAddresses;
    uint256[] private limitAddress;

    constructor() payable ERC721("The Patriot Genesis : PASS", "PATRIOT") {
        mintPrice = 0.025 ether;
        publicMintPrice = 0.035 ether;
        mintPriceZero = 0 ether;
        totalSupply = 0;
        maxSupply = 666;
        maxPerWallet = 2;
    }

    function setIsPublicMintEnabled(bool _isPublicMintEnabled) public onlyOwner {
        isPublicMintEnabled = _isPublicMintEnabled;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseTokenURI(string memory _baseTokenUri) public onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenUri));
    }

    function checkAvailabilityAddress(address _userAddress) public view returns (uint256){
        uint i = 0;
        while(i < whitelistedAddresses.length){
            if(whitelistedAddresses[i] == _userAddress){
                return limitAddress[i] - walletMints[_userAddress];
            }
            i++;
        }
        return 0;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = devAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setAddress(address payable _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }

    function isAddressWhiteListed(address _user) private view returns(bool){
        uint i = 0;
        while(i < whitelistedAddresses.length){
            if(whitelistedAddresses[i] == _user){
                return true;
            }
            i++;
        }
        return false;
    }

    function checkFreeMintAddress(address _userAddress) public view returns (uint256){
        uint i = 0;
        while(i < freeMintAddresses.length){
            if(freeMintAddresses[i] == _userAddress){
                return mintPriceZero;
            }
            i++;
        }
        return mintPrice;
    }

    function isAddressWhiteListedLimit(address _user, uint256 _numberToken) private view returns(bool){
        uint i = 0;
        while(i < whitelistedAddresses.length){
            if(whitelistedAddresses[i] == _user){
                if(limitAddress[i] >= _numberToken){
                    return true;
                }
            }
            i++;
        }
        return false;
    }

    function isAddressFreeMint(address _user) private view returns(bool){
        uint i = 0;
        while(i < freeMintAddresses.length){
            if(freeMintAddresses[i] == _user){
                return true;
            }
            i++;
        }
        return false;
    }

    function setWhitelist(address[] calldata _addressArray) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _addressArray;
    }

    function setWhitelistLimit(uint256[] calldata _limitAddress) public onlyOwner{
        delete limitAddress;
        limitAddress = _limitAddress;
    }

    function setFreeMintList(address[] calldata _addressArray) public onlyOwner {
        delete freeMintAddresses;
        freeMintAddresses = _addressArray;
    }

    function mint(uint256 _numberOfTokens) public payable {
        // require(_numberOfTokens != 1, "You can only mint 1 NFT at a time");
        if(isPublicMintEnabled){
            require(isPublicMintEnabled, "Public mint is not enabled");
            require(totalSupply < maxSupply, "Sale has already ended");
            require(totalSupply + _numberOfTokens <= maxSupply, "Exceeds max supply");
            require(publicWalletMints[msg.sender] + _numberOfTokens <= maxPerWallet, "Maximum Limit Mint Reached");
            require(publicMintPrice * _numberOfTokens <= msg.value, "Ether value sent is not correct");
            for (uint index = 0; index < _numberOfTokens; index++) {
                uint256 newTokenId = totalSupply+1;
                totalSupply++;
                publicWalletMints[msg.sender]++;
                _safeMint(msg.sender, newTokenId);
            }
        }
        else{
            require(totalSupply < maxSupply, "Sale has already ended");
            require(totalSupply + _numberOfTokens <= maxSupply, "Exceeds max supply");
            if(whitelistedAddresses.length > 0){
                require(isAddressWhiteListed(msg.sender), "Not in the whitelist");
                if(isAddressFreeMint(msg.sender)){
    
                }
                else{
                    require(mintPrice * _numberOfTokens <= msg.value, "Ether value sent is not correct");
                }
                require(isAddressWhiteListedLimit(msg.sender, walletMints[msg.sender] + _numberOfTokens), "Exceed limit whitelist wallet");
            }
    
            for (uint index = 0; index < _numberOfTokens; index++) {
                uint256 newTokenId = totalSupply+1;
                totalSupply++;
                walletMints[msg.sender]++;
                _safeMint(msg.sender, newTokenId);
            }
        }

    }
}