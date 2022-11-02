//SPDX-License-Identifier: MIT

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████-
-███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████-
-███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████-
-██████▀"                                                                                                        '▀███▀'                                    "▀██████-
-█████                                                                                                              ▀                                          █████-
-████:        ////// /////// //// //// ///////                                                                             ////// /////// //// //// ///////    :████-
-████        ///       ////           ///                                                                                 ///       ////           ///          ████-
-████       /// ///// //// //// //// ///////                            █ █▀█ █ █ █▀▄ █  █ █▀ █ █  █▀█ █▀▄ █▀█ █▀█       /// ///// //// //// //// ///////       ████-
-████      /// // // //// //// //       ///                             █ █ █ █ █ █ █ █▄ █ █  █ █  █ █ █ █ █ ▀ █ ▀      /// // // //// //// //       ///        ████-
-████     /// ///// //// //// //// ///////                              █ █ █ █ █ █▄▀ █ ██ █▀ ▀▄▀  █▄█ █▄█ ▀▀▄ ▀▀▄     /// ///// //// //// //// ///////         ████-
-████    ///       ////. C  O  Z  I  E  S .                           █▄█ █▄█ ▀▄▀ █ █ █  █ █▄  █   █   █ █ █▄█ █▄█    ///       ////. C  O  Z  I  E  S .        ████-
-████   ///////// ////////////// // // //                                                                            ///////// ////////////// // // //          ████-
-████                                                                                                                                                           ████-
-████                                                                                                                                                           ████-
-████                                                                                                                                                           ████-
-████   ::::  :::  :::: :::::::  ::::::.     .::::.       :.               .::::.   .:::::.   ::::::::: :::   :::   █   █ █▀ █▀█ █▀█   █▄     ▄▀▄ ▄▀▄ █▀█ █ █   ████-
-████   ::::  :::  :::: :::::::  ::::::::   ::::::::      :::.            :::::::  .:::::::.  ::::::::: :::   :::   █ █ █ █  █ █   █   ███▄   █   █ █ ▀ █ █ █   ████-
-████   ::::  :::  :::: ::::     :::: :::   ::: ::::      :::::.         .:::"  "  :::' ':::       :::: :::. .:::   █ █ █ █▀ █▀▄  ▀█   ███▀   █   █ █ ▄▀▀ ▀▄▀   ████-
-████   ::::..:::..:::: ::::     :::: :::   ::: ::::      :::::::.       ::::      :::   :::      ::::  ":::::::"   ▀▄▀▄▀ █▄ █▄█ █▄█   █▀     ▀▄▀ ▀▄▀ █▄█  █    ████-
-████   ::::::::::::::: ::::     :::: :::      .:::.      ::::::::.      :::"      :::   :::     .:::'   :::::::                                                ████-
-████   ::::::::::::::: :::::::  :::::::      .::::       ::::::::::     :::'      :::   :::     :::"     :::::                                                 ████-
-████    :::::::::::::  :::::::  ::::::::      ::::.      ::::::::.      :::'      :::   :::    ::::       :::      :::::::::::::::::::::::                     ████-
-████    :::::: ::::::  ::::     :::: :::       .:::      :::::::'       :::,      :::   :::   ::::        :::      ::::::: ::::: :: :   ::: :: ::::: :         ████-
-████     ::::   ::::   ::::     :::: :::   ::: .:::      :::::'         ":::   .  :::. .:::  ::::         :::                                                  ████-
-████      :::   :::    :::::::  ::::::::   ::::::::      :::"           ':::::::  ":::::::"  :::::::::    :::               █▀▀▀▀▀█ ▄ █ ▀█▄█▄ █▀▀▀▀▀█          ████-
-████       ::   ::     :::::::  :::::::     "::::"       :"               "::::'   ":::::"   :::::::::    :::               █ ███ █ ▄▄▄ █▀▄ ▀ █ ███ █          ████-
-████                                                                                                                        █ ▀▀▀ █ ▄█ ▄▄  ▄█ █ ▀▀▀ █          ████-
-████                                                                                                                        ▀▀▀▀▀▀▀ ▀▄█▄▀ █▄▀ ▀▀▀▀▀▀▀          ████-
-████                                                                                                                        ▀▀▀▀▀ ▀██▀▄▀▄▄▄ ▄▀ █ ▀ █           ████-
-████       █▀▄ ▄▀▄ ▄▀▀ ▄▀▀ ██▀ █▄ █ ▄▀  ██▀ █▀▄      ▄▀▀ ▄▀▄ █▀▄ ██▀       █▀▄ ██▀ █▀▄ ▄▀▄ █▀▄ ▀█▀ █ █ █▀▄ ██▀              ▀▀▀▄▄█▀▀█ ▀ ▄█▀▀▄█ ▀▀▀ ▀█          ████-
-████       █▀  █▀█ ▄██ ▄██ █▄▄ █ ▀█ ▀▄█ █▄▄ █▀▄      ▀▄▄ ▀▄▀ █▄▀ █▄▄       █▄▀ █▄▄ █▀  █▀█ █▀▄  █  ▀▄█ █▀▄ █▄▄              ▄▀▄ ▀ ▀▀▄▀▀ ▀ ▀  █▀▄▀▄▀█▀          ████-
-████                                                                                                                        █ ▀ ██▀▀▄█ █▀ ▄▀▀  ██▀ ▀█          ████-
-████                                             ▄▀▀ ▄▀▄ ▀█▀    ▄█ ▀██ █▄     ▄▀▀ ▀█▀ ▄▀▄ █▄ █ █▀▄   ██▄ ▀▄▀                ▀  ▀  ▀▀▄  ▀▄▄▄▀█▀▀▀█▄▀            ████-
-████                                             ▀▄▄ ▀▄▀ █▄▄ ▀▀  █ ▄▄█ ▄█     ▄██  █  █▀█ █ ▀█ █▄▀   █▄█  █                 █▀▀▀▀▀█ ▀ █ ▄█▀ █ ▀ █▄▀██          ████-
-████:                                                                                                                       █ ███ █ █▀▀ ▀ ▀▀▀██▀█▄█▄█         :████-
-████:                                                                                                                       █ ▀▀▀ █ ██ █▀ ▄▄▄  ▄▄█▀ █         :████-
-█████                                                                                                              ▄        ▀▀▀▀▀▀▀ ▀▀▀▀     ▀▀▀▀▀▀▀▀         █████-
-██████▄_                                                                                                        _▄███▄_                                   ._▄██████-
-███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████-
-███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████-
-███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████-
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
Cozies Whitepaper [https://cozies.gitbook.io/cozies/]

Cozies NFT Terms & Conditions [https://cozies.io/terms]

CantBeEvil NFT License (written by a16z) Non-Exclusive Commercial Rights with Creator Retention & Hate Speech Termination (“CBE-NECR-HS”) 

[https://7q7win2vvm2wnqvltzauqamrnuyhq3jn57yqad2nrgau4fe3l5ya.arweave.net/_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/3]*/ 

pragma solidity 0.8.9;

import "./interfaces/ICozies.sol";
import "./interfaces/IDiamondTicket.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

error InvalidTime();
error InvalidInput();
error InvalidSignature();
error InvalidAddress();
error InvalidAmountETH();
error ExceedAmount();
error TokenNotExist();

contract DiamondTicketStorage {
    address public constant cozies = address(0xEf5C87717aA196D215b4F872FaC3dA77fC5A10E1);

    /// Set with #setSigner
    address public signer;
    /// Set with #setTreasury
    address public treasury;
    /// Set with #setMintPrice
    uint256 public mintPrice;
    /// Set with #setCutPrice
    uint256 public cutPrice;
    /// Set with #setMaxTicketAmount
    uint256 public maxTicketAmount = 9547;

    /// Set with #setWhitelistMintPhase
    uint256 public mintWhitelistStartTime;
    uint256 public mintWhitelistEndTime;
    /// Set with #setPublicMintPhase
    uint256 public mintPublicStartTime;
    uint256 public mintPublicEndTime;
    /// Set with #setCutTicketPhase
    uint256 public cutTicketStartTime;
    uint256 public cutTicketEndTime;

    /// Set with #setBaseURI
    string public baseURI;
    string public uriSuffix;

    /// @notice An address can only mint once during whitelist mint
    mapping (address => uint256) public whitelistMintedAmount;
}

contract DiamondTicket is 
    IDiamondTicket, 
    DiamondTicketStorage,
    ReentrancyGuard,
    Ownable,
    ERC721AQueryable,
    ERC721ABurnable,
    ERC2981 {

    using Strings for uint256;

    constructor(
        uint256 _mintPrice,
        uint256 _cutPrice,
        uint96 _royaltyFee,
        string memory _tokenURI,
        string memory _uriSuffix
    )
        ERC721A("DiamondTicket", "DIAMOND")
    {
        // If any price is zer0
        if (_cutPrice == 0) {
            revert InvalidInput();
        }

        mintPrice = _mintPrice;
        cutPrice = _cutPrice;
        baseURI = _tokenURI;
        uriSuffix = _uriSuffix;

        treasury = owner();
        signer = owner();

        _setDefaultRoyalty(owner(), _royaltyFee);
    }

      ///////////////
     // Modifiers //
    ///////////////

    modifier mintWhitelistActive() {
        // If it's not yet or after the public mint time
        if (block.timestamp <= mintWhitelistStartTime || block.timestamp >= mintWhitelistEndTime) {
            revert InvalidTime();
        }
        _;
    }

    modifier mintPublicActive() {
        // If it's not yet or after the public mint time
        if (block.timestamp <= mintPublicStartTime || block.timestamp >= mintPublicEndTime) {
            revert InvalidTime();
        }
        _;
    }

    modifier cutTicketActive() {
        // If it's not yet or after the cut ticket time
        if (block.timestamp <= cutTicketStartTime || block.timestamp >= cutTicketEndTime) {
            revert InvalidTime();
        }
        _;
    }

    modifier notDuringSales() {
        // If it's during mint time, we shouldn't be modifying mint related parameters
        if ((block.timestamp > mintWhitelistStartTime &&
            block.timestamp < mintWhitelistEndTime) ||
            (block.timestamp > mintPublicStartTime &&
            block.timestamp < mintPublicEndTime)) {
            revert InvalidTime();
        }
        _;
    }

    modifier setTimeCheck(uint256 _startTime, uint256 _endTime) {
        // If we set the start time before end time
        if (_startTime > _endTime) {
            revert InvalidInput();
        }
        _;
    }

    modifier timeInBetween(uint256 _startTime, uint256 _endTime) {
        // If it's between start time and end time, we shouldn't be modifying related parameters
        if (block.timestamp > _startTime && block.timestamp < _endTime) {
            revert InvalidTime();
        } 
        _;
    }

    modifier priceCheck(uint256 _price) {
        // If the price is zero
        if (_price == 0) {
            revert InvalidInput();
        }
        _;
    }

      //////////////////////////////
     // User Execution Functions //
    //////////////////////////////

    /** 
     * @dev Override same interface function in different inheritance.
     * @param interfaceId Id of an interface to check whether the contract support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Check whether an address is in the list
     * @dev Check whether the signature generation process is abnormal
     * @param _maxMintableQuantity Maximum Quantity of tokens that an address can mint
     * @param _signature Signature used to verify the address is in the list
     */
    function verify(
        uint256 _maxMintableQuantity, 
        bytes calldata _signature
    ) 
        public
        override
        view
        returns(bool _whitelisted)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(msg.sender, _maxMintableQuantity)
            )
        );

        return ECDSA.recover(hash, _signature) == signer;
    }

    /** 
     * @dev Mint designated amount of tickets to an address as owner
     * @param _to Address to transfer the tickets
     * @param _quantity Designated amount of tickets
     */
    function giveawayTicket(
        address _to, 
        uint256 _quantity
    ) 
        external
        override
        onlyOwner
    {
        _safeMint(_to, _quantity);
    }

    /**
     * @dev Mint tickets as whitelisted addresses
     * @param _quantity Quantity of ticket that the address wants to mint
     * @param _maxMintableQuantity Maximum Quantity of ticket that the address can mint
     * @param _signature Signature used to verify the address is in the whitelist
     */
    function mintWhitelistTicket(
        uint256 _quantity, 
        uint256 _maxMintableQuantity, 
        bytes calldata _signature
    )
        external
        override
        mintWhitelistActive
    {
        // If this signature is from a valid signer
        if (!verify(_maxMintableQuantity, _signature)) {
            revert InvalidSignature();
        }

        whitelistMintedAmount[msg.sender] += _quantity;

        // If the address has already minted
        if (whitelistMintedAmount[msg.sender] > _maxMintableQuantity) {
            revert ExceedAmount();
        }

        _safeMint(msg.sender, _quantity);
    }

    /** 
     * @notice Each Tx can only mint one ticket
     * @dev Mint tickets with any address
     */
    function mintPublicTicket()
        external
        override
        payable
        mintPublicActive
    {
        // If the mint price is activated
        if (msg.value != mintPrice) {
            revert InvalidAmountETH();
        }

        _safeMint(msg.sender, 1);
    }

    /**
     * @dev Internal minting called by #giveawayTicket, #mintWhitelistTicket, and #mintPublicTicket
     * @param _to Address to mint tickets
     * @param _quantity Amount of tickets
     */
    function _safeMint(
        address _to, 
        uint256 _quantity
    ) 
        internal 
        override 
    {
        // Check if the mint amount will exceed the maximum token supply
        if (_totalMinted() + _quantity > maxTicketAmount) {
            revert ExceedAmount();
        }

        super._safeMint(_to, _quantity);
    }

    /** 
     * @dev User can burn tickets and mint Cozies
     * @dev Every ticket has a unique tokenId
     * @param _tokenIds List of tickets to be burned
     */
    function cutTicket(uint256[] calldata _tokenIds) 
        external
        override
        payable
        nonReentrant
        cutTicketActive
    {
        uint256 quantity = _tokenIds.length;

        if (msg.value != quantity * cutPrice) {
            revert InvalidAmountETH();
        }

        for (uint256 i; i < quantity; ) {
            burn(_tokenIds[i]);
            // increase i without checking overflow
            unchecked {
                i++;
            }
        }

        ICozies(cozies).mintForAddress(quantity, msg.sender);
        emit CutTicket(msg.sender, quantity);
    }

    /** 
     * @dev Retrieve token URI to get the metadata of a token
     * @param _tokenId TokenId which caller wants to get the metadata of
     */
	function tokenURI(uint256 _tokenId) 
        public 
        view 
        override 
        returns (string memory _tokenURI) 
    {
        if (!_exists(_tokenId)) {
            revert TokenNotExist();
        }
        
		return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString(), uriSuffix))
            : '';
	}

    /**
     * @dev For UI to get the total minted and determine if sold out
     */
    function totalMinted()
        public
        view
        returns (uint256 _minted)
    {
        return _totalMinted();
    }

      /////////////////////////
     // Set Phase Functions //
    /////////////////////////
    
    /** 
     * @dev Set the mint time for whitelist users
     * @param _startTime After this timestamp the mint phase will be enabled
     * @param _endTime After this timestamp the mint phase will be disabled
     */
    function setWhitelistMintPhase(
        uint256 _startTime,
        uint256 _endTime
    ) 
        external
        override
        onlyOwner
        setTimeCheck(_startTime, _endTime)
    {
        // If public mint time overlaps with whitelist mint time
        if ((_startTime >= mintPublicStartTime &&_startTime <= mintPublicEndTime) ||
            (_endTime >= mintPublicStartTime && _endTime <= mintPublicEndTime) ||
            (_startTime <= mintPublicStartTime && _endTime >= mintPublicEndTime)) {
            revert InvalidInput();
        }
        
        mintWhitelistStartTime = _startTime;
        mintWhitelistEndTime = _endTime;
        emit PhaseSet(_startTime, _endTime, "Whitelist");
    }

    /** 
     * @dev Set the mint time for all users
     * @param _startTime After this timestamp the mint phase will be enabled
     * @param _endTime After this timestamp the mint phase will be disabled
     */
    function setPublicMintPhase(
        uint256 _startTime,
        uint256 _endTime
    )
        external
        override
        onlyOwner
        setTimeCheck(_startTime, _endTime)
    {
        // If public mint time overlaps with whitelist mint time
        // Or the public mint time is after mint price init time
        if ((_startTime >= mintWhitelistStartTime && _startTime <= mintWhitelistEndTime) ||
            (_endTime >= mintWhitelistStartTime && _endTime <= mintWhitelistEndTime) ||
            (_startTime <= mintWhitelistStartTime && _endTime >= mintWhitelistEndTime)) {
            revert InvalidInput();
        }
        
        mintPublicStartTime = _startTime;
        mintPublicEndTime = _endTime;
        emit PhaseSet(_startTime, _endTime, "Public");
    }

    /** 
     * @dev Set the cut ticket time for ticket holders
     * @param _startTime After this timestamp the cut ticket phase will be enabled
     * @param _endTime After this timestamp the cut ticket phase will be disabled
     */
    function setCutTicketPhase(
        uint256 _startTime,
        uint256 _endTime
    )
        external
        override
        onlyOwner
        setTimeCheck(_startTime, _endTime)
    {
        cutTicketStartTime = _startTime;
        cutTicketEndTime = _endTime;
        emit PhaseSet(_startTime, _endTime, "Cut");
    }

      //////////////////////////
     // Set Params Functions //
    //////////////////////////

    /**
     * @dev Set the price of public mint price
     * @notice Price will be activated after mint price init time
     * @param _price New mint price
     */
    function setMintPrice(uint256 _price) 
        external
        override
        onlyOwner
        priceCheck(_price)
        timeInBetween(mintPublicStartTime, mintPublicEndTime)
    {
        mintPrice = _price;
        emit NumberSet(_price, "MintPrice");
    }

    /**
     * @dev Set the price to cut tickets and mint Cozies
     * @param _price New cut price
     */
    function setCutPrice(uint256 _price) 
        external
        override
        onlyOwner
        priceCheck(_price)
        timeInBetween(cutTicketStartTime, cutTicketEndTime)
    {
        cutPrice = _price;  
        emit NumberSet(_price, "CutPrice");
    }

    /**
     * @dev Set the maximum mintable tier amount in each phase
     * @param _amount Maximum tier amount
     */
    function setMaxTicketAmount(uint256 _amount)
        external
        override
        onlyOwner
        notDuringSales
    {
        // If the new maximum tier token supply is 
        // larger than the maximum token supply or
        // smaller than the total supply
        if (_amount > 9547 || _amount < _totalMinted()) {
            revert InvalidInput();
        }

        maxTicketAmount = _amount;
        emit NumberSet(_amount, "Max");
    }

    /** 
     * @dev Set the royalties information for platforms that support ERC2981, LooksRare & X2Y2
     * @param _receiver Address that should receive royalties
     * @param _feeNumerator Amount of royalties that collection creator wants to receive
     */
    function setDefaultRoyalty(
        address _receiver, 
        uint96 _feeNumerator
    )
        external
        override
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /** 
     * @dev Set the royalties information for platforms that support ERC2981, LooksRare & X2Y2
     * @param _tokenId Id of the token we are setting
     * @param _receiver Address that should receive royalties
     * @param _feeNumerator Amount of royalties that collection creator wants to receive
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) 
        external 
        override
        onlyOwner 
    {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /** 
     * @dev Set the base URI for tokenURI, which returns the metadata of the tokens
     * @param _baseURI Base URI that caller wants to set with tokenURI
     */
    function setBaseURI(string memory _baseURI)
        external
        override
        onlyOwner
    {
        baseURI = _baseURI;
        emit URISet(_baseURI, "BaseURI");
    }

    /** 
     * @dev Set the URI suffix for tokenURI, which returns the metadata of the tokens
     * @param _uriSuffix URI suffix that caller wants to set with tokenURI
     */
    function setURISuffix(string memory _uriSuffix)
        external
        override
        onlyOwner
    {
        uriSuffix = _uriSuffix;
        emit URISet(_uriSuffix, "Suffix");
    }

    /** 
     * @dev Set the address that act as treasury and recieve all the fund in this contract
     * @param _treasury New address that caller wants to set as the treasury address
     */
    function setTreasury(address _treasury)
        external
        override
        onlyOwner
    {
        // If the new address is zero
        if (_treasury == address(0)) {
            revert InvalidAddress();
        }

        treasury = _treasury;
        emit AddressSet(_treasury, "Treasury");
    }

    /** 
     * @dev Set the address that act as the signer for whitelist address
     * @param _signer New signer address
     */
    function setSigner(address _signer)
        external
        override
        onlyOwner
    {
        // If the new address is zero
        if (_signer == address(0)) {
            revert InvalidAddress();
        }

        signer = _signer;
        emit AddressSet(_signer, "Signer");
    }

      /////////////////////
     // Admin Functions //
    /////////////////////

    /**
     * @dev Transfer the ownership of Cozies to another address (EOA)
     * @param _owner Address of Cozies new onwer
     */
    function transferCoziesOwnership(address _owner)
        external
        override
        onlyOwner
    {
        // If the new owner address is zero
        if (_owner == address(0)) {
            revert InvalidAddress();
        }

        ICozies(cozies).transferOwnership(_owner);
    }

    /** 
     * @dev Retrieve fund from this contract to the treasury with the according amount
     * @param _amount The amount of fund that the caller wants to retrieve
     */
    function withdraw(uint256 _amount)
        external
        override
        onlyOwner
    {
        payable(treasury).transfer(_amount);
        emit FundWithdraw(_amount, treasury);
    }
}