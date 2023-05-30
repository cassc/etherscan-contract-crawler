//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
Snails_new.sol
Contract by @Gopnik
thanks to @NftDoyler
*/

contract Gopniks is Ownable, ERC721A {
    uint256 constant public MAX_SUPPLY = 5555;
    uint256 public TEAM_MINT_MAX = 269;

    uint256 public publicPrice = 0.029 ether;

    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 10;
    uint256 constant public PUBLIC_MINT_LIMIT = 20;

    uint256 public TOTAL_SUPPLY_TEAM;

    string public BASE_URI;

    string public CONTRACT_URI = "https://nftstorage.link/ipfs/bafkreiach7274fnpier3fdb3q3u44bsyzzpr47j5hpoecqv66dgwzuzkke";

    bool public paused = true;

    address public teamWallet = 0xE8FCF5d986ccf850F435098ED487070a942B400C;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Gopnik Collection", "GPNK") { }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
            value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    //Public Functions

    function teamMint(uint256 quantity) public payable mintCompliance(quantity) {
        require(msg.sender == teamWallet, "Team minting only");
        require(TOTAL_SUPPLY_TEAM + quantity <= TEAM_MINT_MAX, "No team mints left");

        TOTAL_SUPPLY_TEAM += quantity;

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");
        require(quantity >= 1, "Minimum to mint is 1");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];
        uint256 countToPay = quantity;

        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");

        if(!userMintedFree[msg.sender]) {
            userMintedFree[msg.sender] = true;
            countToPay = countToPay - 1;
        }

        refundOverpay(price * countToPay);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    //View Functions

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function hasUserMintedFree(address _owner) public view returns (bool) {
        return userMintedFree[_owner];
    }

    // Owner Functions

    function setTeamMintMax(uint256 _teamMintMax) public onlyOwner {
        TEAM_MINT_MAX = _teamMintMax;
    }

    // Amount in wei
    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        BASE_URI = _baseUri;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function withdraw() external onlyOwner {
        (bool succ, ) = payable(teamWallet).call{
        value: address(this).balance
        }("");
        require(succ, "Withdraw failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
    // Note: These will likely end up hidden on OpenSea
    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

    // Modifiers

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}