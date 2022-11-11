// SPDX-License-Identifier: MIT

/*........................................................................................
..........................................................................................
.........................................::--:............................................
......................................:=+++++++=.................:-==-:...................
.....................................=++++++++++=..............-++++++++:.................
...................................:=++++++++++++............:=++++++++++.................
..................................:+++=--===+=++=...........-====--+=++++-................
.................................:+++-    ======:.........:====:   -====+-................
................................:===:     =====-.........:====.    :=====:................
...............................:===-     :=====.........-====.     =====-.................
...............................====     .=====.........-====.     -=====..................
..............................-===.    .=====.........-====.     -=====...................
..............................===-    .=====.........-====.     -=====....................
.............................-===     ====-.........:===-     .=====-.....................
.............................===:    -===-.........:===-     -====-.......................
............................:===    :===-.........:===:    .====-:........................
............................-===    ====..::::::.:===:    -===-:..........................
............................===:   :================.   .===-:............................
...........................:===. :-================.   -===:..............................
...........................:=======================:..====++=:............................
...........................-==============================++++=...........................
..........................-================================+++++:.........................
........................:================:....:=============+++++-........................
.......................:.:-.============  .+**=.-===========++++++:.......................
........................-##=.==========: .######.===========+++++++.......................
......................- *### ==========. -######=:==========+++++++-......................
......................- ####.==========  =######*:==========+++++++-......................
.....................:- #### ==:.:=====  =######*:==========+++++++-......................
.....................:- ###* =.....====  =######+:=========+++++++=:......................
......................- *##= . ==:  :==. =######=-=========++++=-.........................
.....................   :*+    .-     .  .#####*:==========--:............................
.....................        ::::::::      ---: .......     ..............................
.....................                                       ..............................
......................                                    ................................
.........................                               ..................................
...............................                     ......................................
....................................:=+=:::::::=##+-:.....................................
...................................*###%%#***#%%%%##*.....................................
...................................################*......................................
................................. :################-.....=#-..............................
.............................:*:.:=###############+::....###+.............................
............................:*#--:-==---:-:--:--==-:.:--+####*:...........................
............................*##-: .. ... . .. . .  ::::-######*...........................
...........................+###:. .. .. .. .. .. ......:#######+..........................
..........................-####: ... .. .. .. .. ... ..=########=.........................
...................................................................Author: @ryanycwEth, C& 
...............................................................Head of Project: @jstin.eth
.....................................................................PR Manager: @Swi Chen
...................................................................Collab Manager: @Ken Ke
............................................................Community Manager: @Hazel Tsai
...............................................................Web Developer: @Mosano Yang
...........................................................Art & Dev Manager: @javic.eth*/

pragma solidity 0.8.4;

import "./interfaces/IGalaxyFrens.sol";
import "erc721psi/contracts/ERC721Psi.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error ExceedAmount();
error NotEnoughQuota();
error InvalidSignature();
error Unauthorized();
error ZeroAddress();
error InvalidInput();
error InvalidToken();
error InvalidTime();
error TokenNotExist();

contract GalaxyFrensStorage {
    uint256 public constant maxGalaxyFrensAmount = 2000;
    uint256 public constant maxRPFHoldersReserve = 900;
    uint256 public constant maxWhitelistReserve = 1800;
    uint256 public constant maxGalaxyFrensPerTx = 10;

    mapping(address => uint256) public rpfHolderMinted;
    mapping(address => uint256) public whitelistMinted;
    mapping(uint256 => uint256) public dreamingStarted;

    /// set with #setAuthorized
    mapping(address => bool) public isAuthorized;
    /// set with #setTokenInvalid and #setTokenValid
    BitMaps.BitMap internal isTokenInvalid;
    /// set with #setMission
    address public mission;
    /// set with #setSignerRPF
    address public signerRPF;
    /// set with #setSignerGF
    address public signerGF;
    /// set with #setBaseURI
    string public baseURI;
    /// set with #setWhitelistMintPhase
    uint256 public rpfHoldersMintStartTime;
    uint256 public rpfHoldersMintEndTime;
    /// set with #setWhitelistMintPhase
    uint256 public whitelistMintStartTime;
    uint256 public whitelistMintEndTime;
    /// set with #setPublicMintPhase
    uint256 public publicMintStartTime;
    uint256 public publicMintEndTime;
    /// set with #setDreamingInitTime
    uint256 public dreamingInitTime;
}

contract GalaxyFrens is 
    IGalaxyFrens, 
    GalaxyFrensStorage,
    ReentrancyGuard,
    Ownable,
    ERC721Psi,
    ERC2981
{
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    constructor(
        uint96 _royaltyFee,
        string memory _baseURI
    ) 
        ERC721Psi("GalaxyFrens", "GF")
    {
        signerRPF = address(0x3D34F69AeD7e3Bb13754a05ED1d95a25968C0C73);
        signerGF = owner();
        isAuthorized[owner()] = true;

        _setDefaultRoyalty(0x19c74DEfdEBB12D37Ab667dA4ADeE3e5D73C82Db, _royaltyFee);

        baseURI = _baseURI;
    }

      ///////////////
     // Modifiers //
    ///////////////

    modifier onlyAuthorized() {
        // Check if the address is in the authorized address array
        if (!isAuthorized[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    modifier rpfHoldersMintActive() {
        // Check if it's not yet mint time or after mint time
        if (block.timestamp <= rpfHoldersMintStartTime || block.timestamp >= rpfHoldersMintEndTime) {
            revert InvalidTime();
        }
        _;
    }

    modifier whitelistMintActive() {
        // Check if it's not yet mint time or after mint time
        if (block.timestamp <= whitelistMintStartTime || block.timestamp >= whitelistMintEndTime) {
            revert InvalidTime();
        }
        _;
    }

    modifier publicMintActive() {
        // Check if it's not yet mint time or after mint time
        if (block.timestamp <= publicMintStartTime || block.timestamp >= publicMintEndTime) {
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

    modifier addressCheck(address _address) {
        // If the new address is zero
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /** 
     * @dev Override same interface function in different inheritance.
     * @param interfaceId Id of an interface to check whether the contract support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Psi, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

      //////////////////////////////
     // User Execution Functions //
    //////////////////////////////

    /**
     * @dev Check whether an address is in the list
     * @dev Check whether the signature generation process is abnormal
     * @param _maxMintableQuantity Maximum Quantity of tokens that an address can mint
     * @param _signature Signature used to verify the address is in the list
     */
    function verify(
        uint256 _maxMintableQuantity, 
        address _signer,
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

        return _signer == ECDSA.recover(hash, _signature);
    }

    /** 
     * @dev Mint designated amount of the Galaxy Frens to an address as owner
     * @param _to Address to transfer the tokens
     * @param _quantity Designated amount of tokens
     */
    function mintGiveawayFrens(
        address _to, 
        uint256 _quantity
    )
        external
        override
        onlyAuthorized
    {
        _safeMint(_to, _quantity);
    }

    /** 
     * @dev Mint the Galaxy Frens as RPF holders
     * @param _quantity Amount of the Galaxy Frens that the caller wants to mint
     * @param _maxQuantity Maximum amount of the Galaxy Frens that the caller can mint
     * @param _signature Signature used to verify the minter address and claimable amount
     */
    function mintRPFHoldersFrens(
        uint256 _quantity,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) 
        external
        override
        rpfHoldersMintActive
    {
        // Check if the mint amount will exceed the maximum tier token supply
        if (totalSupply() + _quantity > maxRPFHoldersReserve) {
            revert ExceedAmount();
        }

        // If this signature is from a valid signer
        if (!verify(_maxQuantity, signerRPF, _signature)) {
            revert InvalidSignature();
        }

        rpfHolderMinted[msg.sender] += _quantity;

        // Check if the whitelist mint amount will exceed the maximum mintable amount
        if (rpfHolderMinted[msg.sender] > _maxQuantity) {
            revert NotEnoughQuota();
        }

        _safeMint(msg.sender, _quantity);
    }

    /** 
     * @dev Mint the Galaxy Frens as whitelisted addresses
     * @param _quantity Amount of the Galaxy Frens that the caller wants to mint
     * @param _maxQuantity Maximum amount of the Galaxy Frens that the caller can mint
     * @param _signature Signature used to verify the minter address and claimable amount
     */
    function mintWhitelistFrens(
        uint256 _quantity,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) 
        external
        override
        whitelistMintActive
    {
        // Check if the mint amount will exceed the maximum tier token supply
        if (totalSupply() + _quantity > maxWhitelistReserve) {
            revert ExceedAmount();
        }

        // If this signature is from a valid signer
        if (!verify(_maxQuantity, signerGF, _signature)) {
            revert InvalidSignature();
        }

        whitelistMinted[msg.sender] += _quantity;

        // Check if the whitelist mint amount will exceed the maximum mintable amount
        if (whitelistMinted[msg.sender] > _maxQuantity) {
            revert NotEnoughQuota();
        }

        _safeMint(msg.sender, _quantity);
    }

    /** 
     * @dev Mint the Galaxy Frens during public sale
     * @param _quantity Amount of the Galaxy Frens the caller wants to mint
     */
    function mintPublicFrens(uint256 _quantity) 
        external
        override
        publicMintActive
    {
        // Check if the mint amount exceed the maximum quantity per tx
        if (_quantity > maxGalaxyFrensPerTx) {
            revert ExceedAmount();
        }

        // Check if the mint amount will exceed the maximum tier token supply
        if (totalSupply() + _quantity > maxWhitelistReserve) {
            revert ExceedAmount();
        }

        _safeMint(msg.sender, _quantity);
    }

    function _safeMint(
        address _to, 
        uint256 _quantity
    ) 
        internal
        override
        nonReentrant
    {
        // Check if the mint amount will exceed the maximum tier token supply
        if (totalSupply() + _quantity > maxGalaxyFrensAmount) {
            revert ExceedAmount();
        }

        super._safeMint(_to, _quantity);
        emit MintGalaxyFrens(_to, _quantity, totalSupply());
    }

      ////////////////////////////
     // Info Getters Functions //
    ////////////////////////////

    /** 
     * @dev Retrieve all tokenIds of a given address
     * @param _owner Address which caller wants to get all of its tokenIds
     */
    function tokensOfOwner(
        address _owner,
        uint256 _start,
        uint256 _end
    )
        public
        view
        override
        returns(uint256[] memory _tokenIds)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256 amount = _end - _start + 1;
            uint256[] memory result = new uint256[](amount);
            for (uint256 index = 0; index < amount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index + _start);
            }
            return result;
        }
    }

    /** 
     * @dev Retrieve the status of whether a token is set to invalid
     * @param _tokenId TokenId which caller wants to get its valid status
     */
    function getTokenValidStatus(uint256 _tokenId)
        public
        view
        override
        returns(bool _status)
    {
        return isTokenInvalid.get(_tokenId);
    }

    /** @dev Retrieve the dreaming period (How long owners hold a token) of a token
     * @param _tokenId TokenId which caller wants to get its dreaming period
     */
    function getDreamingPeriod(uint256 _tokenId) 
        public
        view
        override
        returns(uint256 _dreamingTime)
    {
        if (dreamingInitTime == 0 || dreamingInitTime > block.timestamp) {
            // If it's not yet the initial dreaming time or it is unset, return zero
            return 0;
        } else if (dreamingStarted[_tokenId] == 0) {
            // If the token haven't been transferred, return current time - the initial dreaming time
            return block.timestamp - dreamingInitTime;
        } else {
            // If the token have been transfered, return current time - the dreaming starting time
            // Which is reset when the token is transferred
            return block.timestamp - dreamingStarted[_tokenId];
        }
    }

    /** 
     * @dev Retrieve all the dreaming period (How long owners hold a token) of the tokens of a giving address.
     * @param _owner Address which caller wants to get all the dreaming period (How long owners hold a token) of its token
     */
    function getDreamingPeriodByOwner(address _owner) 
        public
        view
        override
        returns(uint256[] memory _dreamingTimeList)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                uint256 tokenId = tokenOfOwnerByIndex(_owner, index);
                result[index] = getDreamingPeriod(tokenId);
            }
            return result;
        }
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
        // Check the token is minted
        if (!_exists(_tokenId)) {
            revert TokenNotExist();
        }
		return string(abi.encodePacked(baseURI, _tokenId.toString()));
	}

      /////////////////////////
     // Set Phase Functions //
    /////////////////////////

    /** 
     * @dev Set the status, starting time, and ending time of the rpf holders mint phase
     * @param _startTime After this timestamp the rpf holders mint phase will be enabled
     * @param _endTime After this timestamp the rpf holders mint phase will be disabled
     * @notice Start time must be smaller than end time
     */
    function setRPFHoldersMintPhase(
        uint256 _startTime, 
        uint256 _endTime
    )
        external
        override
        onlyAuthorized
        setTimeCheck(_startTime, _endTime)
    {
        rpfHoldersMintStartTime = _startTime;
        rpfHoldersMintEndTime = _endTime;

        emit PhaseSet(_startTime, _endTime, "RPFHolders");
    }

    /** 
     * @dev Set the status, starting time, and ending time of the whitelist mint phase
     * @param _startTime After this timestamp the whitelist mint phase will be enabled
     * @param _endTime After this timestamp the whitelist mint phase will be disabled
     * @notice Start time must be smaller than end time
     */
    function setWhitelistMintPhase(
        uint256 _startTime, 
        uint256 _endTime
    )
        external
        override
        onlyAuthorized
        setTimeCheck(_startTime, _endTime)
    {
        whitelistMintStartTime = _startTime;
        whitelistMintEndTime = _endTime;

        emit PhaseSet(_startTime, _endTime, "Whitelist");
    }

    /** 
     * @dev Set the status, starting time, and ending time of the public mint phase
     * @param _startTime After this timestamp the public mint phase will be enabled
     * @param _endTime After this timestamp the public mint phase will be disabled
     * @notice Start time must be smaller than end time
     */
    function setPublicMintPhase(
        uint256 _startTime, 
        uint256 _endTime
    )
        external
        override
        onlyAuthorized
        setTimeCheck(_startTime, _endTime)
    {
        publicMintStartTime = _startTime;
        publicMintEndTime = _endTime;

        emit PhaseSet(_startTime, _endTime, "Public");
    }

      ////////////////////////////////////////
     // Set Roles & Token Status Functions //
    ////////////////////////////////////////

    /** 
     * @dev Set the status of whether an address is authorized
     * @param _authorizer Address to change its authorized status
     * @param _status New status to assign to the authorizedAddress
     */
    function setAuthorizer(
        address _authorizer, 
        bool _status
    )
        external
        override
        onlyOwner
    {
        isAuthorized[_authorizer] = _status;

        emit StatusChange(_authorizer, _status);
    }

    /** 
     * @dev Set the status of whether an address is signer
     * @param _signer Address to change its status as a signer
     */
    function setSignerRPF(address _signer)
        external
        override
        onlyOwner
        addressCheck(_signer)
    {
        signerRPF = _signer;

        emit AddressSet(_signer, "SignRPF");
    }

    /** 
     * @dev Set the status of whether an address is signer
     * @param _signer Address to change its status as a signer
     */
    function setSignerGF(address _signer)
        external
        override
        onlyOwner
        addressCheck(_signer)
    {
        signerGF = _signer;

        emit AddressSet(_signer, "SignGF");
    }

    /** 
     * @dev Set the specific token to invalid, to revert the transfering transaction
     * @param _tokenId Token Id that owner wants to set to invalid
     */
    function setTokenInvalid(uint256 _tokenId)
        external
        override
        onlyOwner
    {
        isTokenInvalid.set(_tokenId);

        emit TokenStatusChange(_tokenId, true);
    }

    /** 
     * @dev Set the specific token to valid, to revert the transfering transaction 
     * @param _tokenId Token Id that owner wants to set to valid
     */
    function setTokenValid(uint256 _tokenId)
        external
        override
        onlyOwner
    {
        isTokenInvalid.unset(_tokenId);

        emit TokenStatusChange(_tokenId, false);
    }

      //////////////////////////
     // Set Params Functions //
    //////////////////////////

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
     * @dev Set the URI for tokenURI, which returns the metadata of the token
     * @param _baseURI New URI that caller wants to set as the tokenURI
     */
    function setBaseURI(string memory _baseURI)
        external
        override
        onlyOwner
    {
        baseURI = _baseURI;

        emit BaseURISet(_baseURI);
    }

    /** 
     * @dev Set the init time for the dreaming period
     * @param _initTime The new timestamp for the dreaming init time
     * @notice Before the dreamingInitTime is set, all dreaming period will be zero
     */
    function setDreamingInitTime(uint256 _initTime)
        external
        override
        onlyOwner
    {
        dreamingInitTime = _initTime;

        emit NumberSet(_initTime, "Dream");
    }

    /** @dev Set the address that act as treasury and recieve all the fund from token contract
     * @param _mission New address that caller wants to set as the treasury address
     */
    function setMission(address _mission)
        external
        override
        onlyOwner
        addressCheck(_mission)
    {
        mission = _mission;

        emit AddressSet(_mission, "Mission");
    }

    /** @dev Checker before token transfer
     * @param _from Address to transfer the token from
     * @param _to Address to recieve the token
     * @param _startTokenId Init Id to start to transfer the tokens
     * @param _quantity Amount of tokens that will be transferred
     * @notice If the token is set to Invalid, then the transfer will be reverted
     * @notice Every time the token is transferred, the dreaming starting time of the token will be resetted.
     */
    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _startTokenId,
        uint256 _quantity
    ) 
        internal
        override
    {
        // If it's mint or burn, no action require
        if (_from == address(0)) {
            return;
        }

        for (
            uint256 tokenId = _startTokenId;
            tokenId < _startTokenId + _quantity;
            ++tokenId
        ) {
            // If the token has any issue, it will be set to invalid and transfer is paused
            if (isTokenInvalid.get(tokenId)) {
                revert InvalidToken();
            }

            // Tokens being transferred to joined missions is permitted
            if (_to != mission) {
                dreamingStarted[tokenId] = block.timestamp;
            }
        }
    }
}