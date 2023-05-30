//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc721a/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
SignificantOthers.sol

Contract by @NftDoyler
*/

contract SignificantOthers is Ownable, ERC721A {
    bytes32 public merkleRoot;

    uint256 constant public MAX_SUPPLY = 5000;
    uint256 constant public TEAM_MINT_MAX = 50;
    uint256 public FREE_MINT_MAX;
    uint256 public PUBLIC_MINT_MAX;
    
    // Unnecessary, this is a free mint!
    //uint256 constant public ALLOW_LIST_PRICE = 0 ether;
    uint256 constant public PUBLIC_PRICE = 0.015 ether;

    uint256 constant public ALLOW_LIST_MINT_LIMIT = 1;

    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 5;
    uint256 constant public PUBLIC_MINT_LIMIT = 10;

    uint256 public totalSupplyTeam;
    uint256 public totalSupplyPublic;

    // Doing these out of 10000 for the fractional percentages
        // I.e.: 1250 = 12.5%
    uint256 constant internal DEV_WITHDRAW_PERCENT = 1250;
    uint256 constant internal ARTIST_WITHDRAW_PERCENT = 1500;
    uint256 constant internal WEB_WITHDRAW_PERCENT = 500;
    uint256 constant internal COMMUNITY_WITHDRAW_PERCENT = 3375;

    string public revealedURI;
    
    // Note: Make this a constant if it is known in advance to save gas.
    string public hiddenURI = "ipfs://Qma7X5atnq9VU3XShutpksKB5xPHeWorD4GsEpDHM1K76N";

    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string public CONTRACT_URI;

    bool public paused = true;
    bool public revealed = false;

    address constant internal DEV_ADDRESS = 0xeD19c8970c7BE64f5AC3f4beBFDDFd571861c3b7;
    address constant internal ARTIST_ADDRESS = 0x5be0D3BE0C8A6E99A26fC8257d969d38a03c8306;
    address constant internal WEB_ADDRESS = 0x70E93674A2f0eE65a5f16baDa5B13952C6671188;
    address constant internal COMMUNITY_ADDRESS = 0x994adAd31b1966c74A3f76419E3Ba91F60E52277;
    
    // Leaving this public as a few failure cases could arrise and need this to change.
    address public teamWallet = 0xA7Fe90781F56C3ce4358bA0cB088Ce03Cc735127;

    mapping(address => bool) public userMintedWL;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Significant Others", "SIGOTHER") { }

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
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _verifyPublicAllowList(bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
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

    function teamMint(uint256 quantity) external payable {
        require(msg.sender == teamWallet, "Team mint only");
        require(totalSupplyTeam + quantity <= TEAM_MINT_MAX, "No team mints left");

        totalSupplyTeam += quantity;

        _safeMint(msg.sender, quantity);
    }
    
    function allowListMint(uint256 quantity, bytes32[] memory proof) external payable mintCompliance(quantity) {
        require(_verifyPublicAllowList(proof), "Not on WL");
        require(!userMintedWL[msg.sender], "Already minted free");
        
        userMintedWL[msg.sender] = true;

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(totalSupplyPublic + quantity <= PUBLIC_MINT_MAX, "Not enough mints left");

        uint256 price = PUBLIC_PRICE;
        uint256 currMints = numUserMints[msg.sender];

        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "5 mints per tx");
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        
        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);
        totalSupplyPublic += quantity;

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

    // Note: walletOfOwner is only really necessary for enumerability when staking/using on websites etc.
        // That said, it's a public view so we can keep it in.
        // This could also be optimized if someone REALLY wanted, but it's just a public view.
        // Check the pinned tweets of 0xInuarashi for more ideas on this method!
        // For now, this is just the version that existed in v1.
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
        // Note: You don't REALLY need this require statement since nothing should be querying for non-existing tokens after reveal.
            // That said, it's a public view method so gas efficiency shouldn't come into play.
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed) {
            return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
        }
        else {
            return hiddenURI;
        }
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    // A shameful bug was caught here by @saintmaxiv - please forgive me and hire him for websites!
    function verifyPublicAllowList(address _address, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_address)));
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

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    // Note: This method can be hidden/removed if this is a constant.
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenURI = _hiddenMetadataUri;
    }

    // This saves a little gas and one method call to handle reveal/URI in one swoop.
    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        revealed = _revealed;
        revealedURI = _baseUri;
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

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxFree(uint256 _freeMax) external onlyOwner {
        FREE_MINT_MAX = _freeMax;
        PUBLIC_MINT_MAX = MAX_SUPPLY - TEAM_MINT_MAX - FREE_MINT_MAX;
    }

    function setPublicMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setTeamWallet(address _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    // Note: The inspiration for this withdrawal method came from MD's work on Kiwami.
        // Be sure to check out their contract for the OG - https://etherscan.io/address/0x701a038af4bd0fc9b69a829ddcb2f61185a49568#code
        // Thanks to @_MouseDev for the big brain ideas.
    function withdraw() external payable onlyOwner {
        // Get the current funds to calculate initial percentages
        uint256 currBalance = address(this).balance;

        (bool succ, ) = payable(DEV_ADDRESS).call{
            value: (currBalance * DEV_WITHDRAW_PERCENT) / 10000
        }("");
        require(succ, "Dev transfer failed");

        (succ, ) = payable(ARTIST_ADDRESS).call{
            value: (currBalance * ARTIST_WITHDRAW_PERCENT) / 10000
        }("");
        require(succ, "Artist transfer failed");

        (succ, ) = payable(WEB_ADDRESS).call{
            value: (currBalance * WEB_WITHDRAW_PERCENT) / 10000
        }("");
        require(succ, "Web transfer failed");

        (succ, ) = payable(COMMUNITY_ADDRESS).call{
            value: (currBalance * COMMUNITY_WITHDRAW_PERCENT) / 10000
        }("");
        require(succ, "Community transfer failed");

        // Withdraw the ENTIRE remaining balance to the deployer wallet
        (succ, ) = payable(teamWallet).call{
            value: address(this).balance
        }("");
        require(succ, "Team (remaining) transfer failed");
    }

    function mintToUser(uint256 quantity, address receiver) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "toUser MAX_SUPPLY");

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
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}