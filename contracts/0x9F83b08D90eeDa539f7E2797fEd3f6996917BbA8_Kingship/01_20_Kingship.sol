// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/***********************************************************************************\
|   ___  __     ___   ________    ________   ________   ___  ___   ___   ________     |
|  |\  \|\  \  |\  \ |\   ___  \ |\   ____\ |\   ____\ |\  \|\  \ |\  \ |\   __  \    |
|  \ \  \/  /|_\ \  \\ \  \\ \  \\ \  \___| \ \  \___|_\ \  \\\  \\ \  \\ \  \|\  \   |
|   \ \   ___  \\ \  \\ \  \\ \  \\ \  \  ___\ \_____  \\ \   __  \\ \  \\ \   ____\  |
|    \ \  \\ \  \\ \  \\ \  \\ \  \\ \  \|\  \\|____|\  \\ \  \ \  \\ \  \\ \  \___|  |
|     \ \__\\ \__\\ \__\\ \__\\ \__\\ \_______\ ____\_\  \\ \__\ \__\\ \__\\ \__\     |
|      \|__| \|__| \|__| \|__| \|__| \|_______||\_________\\|__|\|__| \|__| \|__|     |
|                                              \|_________|                           |
 \***********************************************************************************/

/**
 * @title Kingship Contract
 * @author Ben Yu, rminla.eth and Itzik Lerner AKA the NFTDevz
 * @notice This contract handles minting Kingship Genesis NFT project.
 */

contract Kingship is ERC721A, Ownable, ReentrancyGuard, Pausable, ERC2981 {
    using ECDSA for bytes32;
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    uint256[] public priceList = [
        0.00409372 ether, // ApeCoin price in ETH
        0.19 ether, // Allowlist wave 1 price
        0.19 ether, // Allowlist wave 2 price
        0.19 ether, // Allowlist wave 3 price
        0.19 ether // Public Sale price
    ];

    // States Wave1, Wave2, Wave3 and PublicSale double as indexes of priceList array
    enum States {
        Premint,
        Wave1,     
        Wave2,
        Wave3,
        PublicSale,
        SaleEnded,
        Redeem
    }

    //events
    event Redeem(address owner, uint256 redemptionBatchId, uint256[] redeemedTokenIds);

    //constants
    uint256 public constant MAX_SUPPLY = 5000;
    address internal APECOIN_CONTRACT = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;

    //token properties
    string public baseTokenURI;
    string public contractURI;

    //commercial properties
    address public royaltyAddress = 0x59705Eb15a3965c75F871977976A8f053BC4B752;
    address public partner1Address = 0x59705Eb15a3965c75F871977976A8f053BC4B752;
    address public partner2Address = 0x59705Eb15a3965c75F871977976A8f053BC4B752;
    address public alternateSigner = 0x8a973CA0A9093768cF9F142b2443dfc1dbE7F5eD;
    uint256 public mintsAllowedPerAddress = 4;
    uint96 public royaltyFee = 650;

    //fairness properties
    uint256 public startingIndex;
    uint256 public startingIndexTimestamp;
    string public provenance = '3ce42f696559f86cca6a32ec60bed95153ffd66085db1d142a4e3f0c1a850663';
    uint256 public provenanceTimestamp;

    //state properties
    bool[] public states = new bool[](7);
    uint256[] public waveAllocations = [0,2000,1000];
    bytes32 public merkleRoot;

    //redemption
    mapping(uint256 => uint256) public redeemed;
    uint256 public redemptionBatchIndex;
    bool sendOnRedeem = false;
    address public redeemAddress;

    /**
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for all tokens
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_
    ) ERC721A(name, symbol) {
        baseTokenURI = baseTokenURI_;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Prevent contract-to-contract calls
     */
    modifier originalUser() {
        require(
            msg.sender == tx.origin,
            "Must invoke directly from your wallet"
        );
        _;
    }

    /**
     * @notice Ensure that required state is enabled
     */
    modifier stateEnabled(States _state) {
        require(
            states[uint256(_state)],
            "Invalid state"
        );
        _;
    }

    /**
     * @notice Ensure that number of mints per address has not been exceeded
     */
    modifier userCanStillMint(uint256 _numTokens) {
        require(
            _numberMinted(msg.sender) + _numTokens <= mintsAllowedPerAddress,
            "Max Mints Per Address Exceeded"
        );
        _;
    }

    /**
     * @notice Ensure that total supply has not been exceeded
     */
    modifier supplyNotExceeded(uint256 _numTokens) {
        require(totalSupply() + _numTokens <= MAX_SUPPLY, "Max Supply Exceeded");
        _;
    }

    /**
     * @notice Change the ApeCoin contract address
     */
    function setApeCoinAddress(address _apeCoinContractAddress) external onlyOwner {
        APECOIN_CONTRACT = _apeCoinContractAddress;
    }

    /**
     * @notice Change starting tokenId to 1 (from erc721A)
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice update wave allocations
     */
    function setWaveAllocations(uint256[] calldata _waveAllocations) external onlyOwner {
        require(
            _waveAllocations.length == waveAllocations.length,
            "Must provide array of all allocations"
        );
        waveAllocations = _waveAllocations;
    }

    /**
     * @notice update priceList
     */
    function setPriceList(uint256[] calldata _priceList) external onlyOwner {
        require(
            _priceList.length == priceList.length,
            "Must provide array of all prices"
        );
        require(_priceList[0] > 0, "ApeCoin to ETH rate must be greater than 0");
        priceList = _priceList;
    }

    /**
     * @notice update apeCoinToEth rate
     */
    function setApeCoinPrice(uint256 _apeCoinToEthRate) external onlyOwner {
        require(_apeCoinToEthRate > 0, "ApeCoin to ETH rate must be greater than 0");
        priceList[0] = _apeCoinToEthRate;
    }

    /**
     * @notice set alternate signer (used for "reserve" functionality)
     */
    function setAlternateSignerAddress(address _alternateSigner) external onlyOwner {
        alternateSigner = _alternateSigner;
    }

    /**
     * @notice Set partner addresses 
     */
    function setPartnerAddresses(address _partner1Address, address _partner2Address) external onlyOwner {
        require(_partner1Address != address(0), "Partner addresses must be valid");
        require(_partner2Address != address(0), "Partner addresses must be valid");
        partner1Address = _partner1Address;
        partner2Address = _partner2Address;
    }

    /**
     * @notice Change the redemption settings
     */
    function changeRedemptionSettings(address _redeemAddress, bool _sendOnRedeem) external onlyOwner {
        redeemAddress = _redeemAddress;
        sendOnRedeem = _sendOnRedeem;
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the number of mints allowed per address
     */
    function setNumberOfMintsPerAddress(uint256 _mintsAllowedPerAddress) external onlyOwner {
        mintsAllowedPerAddress = _mintsAllowedPerAddress;
    }

    /**
     * @notice Sets a provenance hash of pregenerated tokens for fairness. Should be set before first token mints
     */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenance = _provenanceHash;
        provenanceTimestamp = block.timestamp;
    }

    /**
     * @notice toggles the state
     */
    function toggleState(uint256 _state) public onlyOwner {
        require(
            _state >= uint256(type(States).min) && _state <= uint256(type(States).max),
            "Invalid state transition: State does not exist"
        );
        states[_state] = !states[_state];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Turn off all sales
     */
    function setSaleEnded() public onlyOwner {
        setSaleEndedState();
    }

    /**
     * @notice Turn off all sales when Max Supply reached
     */
    function setSaleEndedState() private {
        states[uint256(States.PublicSale)] = false;
        states[uint256(States.Wave1)] = false;
        states[uint256(States.Wave2)] = false;
        states[uint256(States.Wave3)] = false;
    }


    /**
     * @notice public sale mint function
     */
    function publicSaleMint(uint256 _numTokens, bool _payWithApeCoin)
        external
        payable
        nonReentrant
        originalUser
        whenNotPaused
        stateEnabled(States.PublicSale)
        userCanStillMint(_numTokens)
        supplyNotExceeded(_numTokens)
    {
        handlePayment(
            priceList[uint256(States.PublicSale)] * _numTokens,
            _payWithApeCoin
        );
        _safeMint(msg.sender, _numTokens);
        if (totalSupply() == MAX_SUPPLY) {
            setSaleEndedState();
        }
    }
        
    /**
     * @notice Allow List Verify
     */
    function allowListVerify(
        uint256 _wave,
        address _address,
        bytes32[] calldata _merkleProof
    ) 
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_wave, _address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Allow List mint function
     */
    function allowListMint(
        uint256 _wave,
        uint256 _numTokens,
        bool _payWithApeCoin,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        nonReentrant
        originalUser
        whenNotPaused
        stateEnabled(States(_wave))
        userCanStillMint(_numTokens)
        supplyNotExceeded(_numTokens)
    {
        require(
            allowListVerify(_wave, msg.sender, _merkleProof),
            "This address is not elegible for the provided allowlist wave"
        );

        // support for allocations 
        if (_wave < uint256(States.Wave3) && !states[uint256(States.Wave3)]) {
            require(waveAllocations[_wave] > 0, 
                "Allocation for your community has been filled. Please try again in the next wave");
            waveAllocations[_wave] = waveAllocations[_wave] < _numTokens ? 0 : 
                                     waveAllocations[_wave] - _numTokens;
        }

        handlePayment(priceList[_wave] * _numTokens, _payWithApeCoin);
        _safeMint(msg.sender, _numTokens);
        if (totalSupply() == MAX_SUPPLY) {
            setSaleEndedState();
        }
    }

    /**
     * @notice common charge function to use on all mint types
     */
    function handlePayment(uint256 _amount, bool _payWithApeCoin) private {
        if (_payWithApeCoin) {
            uint256 apeCoinToEthRate = priceList[0];
            require(apeCoinToEthRate > 0, "ApeCoin to ETH rate must be greater than 0");
            IERC20(APECOIN_CONTRACT).safeTransferFrom(
                msg.sender,
                address(this),
                _amount.mul(100000).div(apeCoinToEthRate).mul(10000000000000) //10 ** 13
            );
        } else {
            require(msg.value >= _amount, "Insufficient Payment");
        }
    }

    /**
     * @notice Allow owner to reserve tokens without cost to a specific addresses
     */
    function reserve(uint256 _numTokens, address _recipient)
        external
        supplyNotExceeded(_numTokens)
    {
        require(msg.sender == alternateSigner);
        _safeMint(_recipient, _numTokens);
    }

    /**
     * @notice Set the starting index for the public and allow list mints
     */
    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "STARTING_INDEX_ALREADY_SET");

        startingIndex = generateRandomStartingIndex(MAX_SUPPLY);
        startingIndexTimestamp = block.timestamp;
    }

    /**
     * @notice Creates a random starting index to offset pregenerated tokens by for fairness
     */
    function generateRandomStartingIndex(uint256 _range)
        private
        view
        returns (uint256)
    {
        uint256 index;
        // Blockhash only works for the most 256 recent blocks.
        uint256 _block_shift = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        _block_shift = 1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        index = uint256(blockhash(_block_ref)) % _range;

        // Prevent default sequence
        // or same last digit
        if (index % 10 == 0) {
            index++;
        }

        return index;
    }

    /**
     * @notice  Allow contract owner to withdraw ETH funds
     *          split between partners.
     */
    function withdraw() public onlyOwner {

        require(partner1Address != address(0), "Must have valid partner1 withdraw address");

        uint256 _balance = address(this).balance;
        require(_balance > 0, 'No ETH to withdraw');
        if (partner1Address == partner2Address) {
            require(payable(partner1Address).send(_balance));
        } else {
            require(partner2Address != address(0), "Must have valid partner2 withdraw address");
            uint256 _split = _balance.mul(90).div(100);
            require(payable(partner1Address).send(_split));
            require(payable(partner2Address).send(_balance.sub(_split)));            
        }
    }

    /**
     * @notice  Allow contract owner to withdraw APECOIN funds
     *          splitted between partners.
     */
    function withdrawApe() public onlyOwner {

        require(partner1Address != address(0), "Must have valid partner1 withdraw address");
    
        uint256 _apecoinBalance = IERC20(APECOIN_CONTRACT).balanceOf(address(this));
        require(_apecoinBalance > 0, 'No APECOIN to withdraw');
        if (partner1Address == partner2Address) {
            IERC20(APECOIN_CONTRACT).safeTransfer(
                partner1Address, _apecoinBalance
            );
        } else {
            require(partner2Address != address(0), "Must have valid partner2 withdraw address");
            uint256 _split = _apecoinBalance.mul(90).div(100);
            IERC20(APECOIN_CONTRACT).safeTransfer(
                partner1Address, _split
            );
            IERC20(APECOIN_CONTRACT).safeTransfer(
                partner2Address, _apecoinBalance.sub(_split)
            );
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Update the contractURI for OpenSea
     *         Update for collection-specific metadata
     *         https://docs.opensea.io/docs/contract-level-metadata
     */
    function setContractURI(string calldata _newContractURI)
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice ADD DESCRIPTION
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }


    /**
     * @notice Check which tower/band member is represented by the tokenId
     */
    function towerOf(uint256 _tokenId) public view returns (uint8) {
        require(startingIndex > 0, "Must first set startingIndex");
        uint8[10] memory towerOrder = [4, 2, 4, 3, 3, 1, 4, 4, 2, 3];
        // 10 groups out of 1000 will have a chance to mint tokens of 4 different towers
        uint8[10] memory rareTowerOrder = [4, 2, 4, 2, 3, 1, 3, 3, 4, 4];
        uint256 originalIndex = (_tokenId + MAX_SUPPLY - startingIndex - 1) % MAX_SUPPLY;
        if (originalIndex % 1000 - originalIndex % 10 == 770) {
            return rareTowerOrder[originalIndex % 10];
        } else {
            return towerOrder[originalIndex % 10];
        }
    }

    /**
     * @notice Check if the set of tokens passed in is valid for redemption 
     */
    function isTokenSetRedeemable(uint256[] memory _tokenIDs) public view returns (bool) {
        return isTokenSetRedeemable(msg.sender, _tokenIDs);
    }


    /**
     * @notice Check if the set of tokens passed in is valid for redemption by the given address
     */
    function isTokenSetRedeemable(address _address, uint256[] memory _tokenIDs)
        public
        view
        returns (bool)
    {
        require(_tokenIDs.length == 4, "Redeemable set must have 4 tokens");
        bool[4] memory towersFound;
        for (uint256 i = 0; i < 4; i++) {
            uint256 tokenId = _tokenIDs[i];
            uint256 currentTower = towerOf(tokenId);
            require(
                redeemed[tokenId] == 0,
                "Token has been redeemed already"
            );
            require(
                !towersFound[currentTower-1],
                "Set must consist of 4 unique tokens"
            );
            require(
                ownerOf(tokenId) == _address,
                "Only the owner of a token can redeem it"
            );
            towersFound[currentTower-1] = true;

        }
        return true;
    }

    /**
     * @notice Allows a user to redeem a set of tokens for a surprise.  Stay tuned!!!!
     */
    function redeem(uint256[] memory _tokenIDs)
        external
        stateEnabled(States.Redeem)
    {
        require(isTokenSetRedeemable(_tokenIDs), "The set is not redeemable");
        redemptionBatchIndex++;
        for (uint256 i = 0; i < 4; i++) {
            redeemed[_tokenIDs[i]] = redemptionBatchIndex;
            //if required, transfer the redeemed token
            if (sendOnRedeem) {
                transferFrom(msg.sender, redeemAddress, _tokenIDs[i]);
            }
        }
        emit Redeem(msg.sender, redemptionBatchIndex, _tokenIDs);
    }

    receive() external payable {}

}