//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
LowBudgetCaptainz.sol
*/

contract LowBudgetCaptainz is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 999;
    uint256 public TEAM_MINT_MAX = 99;

    uint256 public publicPrice = 0.0025 ether;

    uint256 public constant PUBLIC_MINT_LIMIT_TXN = 3;
    uint256 public constant PUBLIC_MINT_LIMIT = 3;

    uint256 public TOTAL_SUPPLY_TEAM;

    string public revealedURI =
        "ipfs://bafybeihjkc2cpeczxhzqxkelvwre7uzxan55ktqgw222pkjwju66bc3l3m/";

    string public hiddenURI =
        "ipfs://bafybeidhbujxyvpapkt7l3bx3htpow35vowux6uj6gh2mdqbzro6rxr4le/hidden.json";

    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string public CONTRACT_URI =
        "ipfs://bafybeidhbujxyvpapkt7l3bx3htpow35vowux6uj6gh2mdqbzro6rxr4le/hidden.json";

    bool public paused = true;
    bool public revealed = true;
    bool public publicSale = true;

    address internal constant devWallet =
        0x89c3F8442b4d40E019e30590F14c7F3884139fa2;
    address public teamWallet = 0x89c3F8442b4d40E019e30590F14c7F3884139fa2;

    uint256 internal devWithdrawPercent = 1000;

    mapping(address => uint256) public numUserMints;

    constructor() ERC721A(" LowBudgetCaptainz", "LBC") {}

    /*
     *

    $$$$$$$\            $$\                      $$\                     $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           \__|                     $$ |                    $$  _____|                             $$ |    \__|                              
    $$ |  $$ | $$$$$$\  $$\ $$\    $$\ $$$$$$\ $$$$$$\    $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$  __$$\ $$ |\$$\  $$  |\____$$\\_$$  _|  $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  \__|$$ | \$$\$$  / $$$$$$$ | $$ |    $$$$$$$$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |      $$ |  \$$$  / $$  __$$ | $$ |$$\ $$   ____|      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      $$ |      $$ |   \$  /  \$$$$$$$ | \$$$$  |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|      \__|      \__|    \_/    \_______|  \____/  \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    // This function is if you want to override the first Token ID# for ERC721A
    // Note: Fun fact - by overloading this method you save a small amount of gas for minting (technically just the first mint)
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        } else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    /*
     *

    $$$$$$$\            $$\       $$\ $$\                 $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           $$ |      $$ |\__|                $$  _____|                             $$ |    \__|                              
    $$ |  $$ |$$\   $$\ $$$$$$$\  $$ |$$\  $$$$$$$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$ |  $$ |$$  __$$\ $$ |$$ |$$  _____|      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  $$ |$$ |  $$ |$$ |$$ |$$ /            $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |  $$ |$$ |  $$ |$$ |$$ |$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      \$$$$$$  |$$$$$$$  |$$ |$$ |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|       \______/ \_______/ \__|\__| \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    function teamMint(
        uint256 quantity
    ) public payable mintCompliance(quantity) {
        require(msg.sender == teamWallet, "Team minting only");
        require(
            TOTAL_SUPPLY_TEAM + quantity <= TEAM_MINT_MAX,
            "No team mints left"
        );
        require(totalSupply() >= 0, "Team mints after public sale");

        TOTAL_SUPPLY_TEAM += quantity;

        _safeMint(msg.sender, quantity);
    }

    function publicMint(
        uint256 quantity
    ) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];

        require(
            currMints + quantity <= PUBLIC_MINT_LIMIT,
            "User max mint limit"
        );

        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    /*
     *

    $$\    $$\ $$\                               $$$$$$$$\                              $$\     $$\                               
    $$ |   $$ |\__|                              $$  _____|                             $$ |    \__|                              
    $$ |   $$ |$$\  $$$$$$\  $$\  $$\  $$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    \$$\  $$  |$$ |$$  __$$\ $$ | $$ | $$ |      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
     \$$\$$  / $$ |$$$$$$$$ |$$ | $$ | $$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
      \$$$  /  $$ |$$   ____|$$ | $$ | $$ |      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
       \$  /   $$ |\$$$$$$$\ \$$$$$\$$$$  |      $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
        \_/    \__| \_______| \_____\____/       \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed) {
            return
                string(
                    abi.encodePacked(
                        revealedURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        } else {
            return hiddenURI;
        }
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /*
     *

     $$$$$$\                                                    $$$$$$$$\                              $$\     $$\                               
    $$  __$$\                                                   $$  _____|                             $$ |    \__|                              
    $$ /  $$ |$$\  $$\  $$\ $$$$$$$\   $$$$$$\   $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$ |  $$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\ $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$$$$$$$ |$$ |  \__|      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$   ____|$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
     $$$$$$  |\$$$$$\$$$$  |$$ |  $$ |\$$$$$$$\ $$ |            $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
     \______/  \_____\____/ \__|  \__| \_______|\__|            \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

     *
     */

    function setTeamMintMax(uint256 _teamMintMax) public onlyOwner {
        TEAM_MINT_MAX = _teamMintMax;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setDevWithdrawCut(uint256 _devPercentage) public onlyOwner {
        devWithdrawPercent = _devPercentage;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    // Note: This method can be hidden/removed if this is a constant.
    function setHiddenMetadataURI(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenURI = _hiddenMetadataUri;
    }

    function revealCollection(
        bool _revealed,
        string memory _baseUri
    ) public onlyOwner {
        revealed = _revealed;
        revealedURI = _baseUri;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function withdraw() external payable onlyOwner {
        // Get the current funds to calculate initial percentages
        uint256 currBalance = address(this).balance;

        (bool succ, ) = payable(devWallet).call{
            value: (currBalance * devWithdrawPercent) / 10000
        }("");
        require(succ, "Dev transfer failed");

        // Withdraw the ENTIRE remaining balance to the team wallet
        (succ, ) = payable(teamWallet).call{value: address(this).balance}("");
        require(succ, "Team (remaining) transfer failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
    // Note: These will likely end up hidden on OpenSea
    function mintToUser(
        uint256 quantity,
        address receiver
    ) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

    /*
     *

    $$\      $$\                 $$\ $$\  $$$$$$\  $$\                               
    $$$\    $$$ |                $$ |\__|$$  __$$\ \__|                              
    $$$$\  $$$$ | $$$$$$\   $$$$$$$ |$$\ $$ /  \__|$$\  $$$$$$\   $$$$$$\   $$$$$$$\ 
    $$\$$\$$ $$ |$$  __$$\ $$  __$$ |$$ |$$$$\     $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ \$$$  $$ |$$ /  $$ |$$ /  $$ |$$ |$$  _|    $$ |$$$$$$$$ |$$ |  \__|\$$$$$$\  
    $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |$$ |$$ |      $$ |$$   ____|$$ |       \____$$\ 
    $$ | \_/ $$ |\$$$$$$  |\$$$$$$$ |$$ |$$ |      $$ |\$$$$$$$\ $$ |      $$$$$$$  |
    \__|     \__| \______/  \_______|\__|\__|      \__| \_______|\__|      \_______/ 

    *
    */

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough mints left"
        );
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}