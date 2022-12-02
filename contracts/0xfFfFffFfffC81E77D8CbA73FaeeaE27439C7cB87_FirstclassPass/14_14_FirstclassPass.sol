// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/// @author: Firstclass Labs
/// @notice: "If you don’t get it, you don’t get it."

//////////////////////////////////////////////////////////////////////////////////
//      _______           __       __                   __          __          //
//     / ____(_)_________/ /______/ /___ ___________   / /   ____ _/ /_  _____  //
//    / /_  / / ___/ ___/ __/ ___/ / __ `/ ___/ ___/  / /   / __ `/ __ \/ ___/  //
//   / __/ / / /  (__  ) /_/ /__/ / /_/ (__  |__  )  / /___/ /_/ / /_/ (__  )   //
//  /_/   /_/_/  /____/\__/\___/_/\__,_/____/____/  /_____/\__,_/_.___/____/    //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

import "@firstclasslabs/erc4907/IERC4907Rentable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/ECDSA.sol";
import "solmate/src/auth/Owned.sol";
import "solmate/src/tokens/ERC721.sol";
import "solmate/src/utils/LibString.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

error F_BadInput();
error F_ExceededMaxSupply();
error F_ExceededPermitted();
error F_Forbidden();
error F_PaymentError();
error F_SignatureExpired();
error F_SignatureInvalid();
error F_SignatureUsed();
error F_TokenNotAvailable();
error F_TokenInUse();
error F_Underpaid();

contract FirstclassPass is
    ERC721,
    ERC2981,
    IERC4907Rentable,
    OperatorFilterer,
    Owned,
    ReentrancyGuard
{
    using LibString for uint256;

    // Maximum number of tokens that will be ever created
    uint256 public immutable maxSupply;

    // The number of tokens that currently exists
    uint256 private totalSupply_;

    // Mint price per token
    uint256 public immutable price;

    // Used to verify ECDSA signatures
    address private signer;

    // Keep track of used signatures
    mapping(bytes32 => bool) private signatures;

    /**
     * @notice Container for ERC4907Rentable data
     * @dev We're bullish on Ethereum but we'll likely be dead before `expires`
     * causes a problem in 2106. Also note that the `rate` is uint64 here as
     * opposed to uint256 defined in the interface. A non-zero `rate` means
     * the token is rentable.
     */
    struct Rentable {
        address user;
        uint32 expires;
        uint64 rate;
    }

    /**
     * @notice Mapping from token ID to packed {Rentable} data
     * @dev Bits layout: [255..192][191..160][159..0]
     *                       `rate` `expires`  `user`
     */
    mapping(uint256 => uint256) private rentables;

    // The mask of the lower 160 bits for `user`
    uint256 private constant BITMASK_USER = (1 << 160) - 1;

    // The mask of the lower 32 bits for `expires`
    uint256 private constant BITMASK_EXPIRES = (1 << 32) - 1;

    // The bit position of `expires`
    uint256 private constant BITPOS_EXPIRES = 160;

    // The bit position of `rate`
    uint256 private constant BITPOS_RATE = 192;

    // Minimum duration per rental
    uint256 private constant MIN_RENTAL_DURATION = 24 hours;

    // Maximum duration per rental
    uint256 private constant MAX_RENTAL_DURATION = 14 days;

    // Minimum rent per second
    uint256 private constant MIN_RENTAL_RATE = 100 gwei;

    // Where the funds should go to
    address private treasury;

    // See {ERC721Metadata}
    string private baseURI;

    // 💎 + 🖖
    uint256 private immutable initiation;

    // Keep track of the last transferred timestamps
    mapping(uint256 => uint256) private lastTransferred;

    // ERC2981 default royalty in bps
    uint96 private constant DEFAULT_ROYALTY_BPS = 1000;

    // See {_operatorFilteringEnabled}
    bool private operatorFiltering = true;

    /**
     * @notice Constructooooooor
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        address _signer,
        address _treasury,
        uint256 _initiation,
        string memory _baseURI
    ) ERC721(_name, _symbol) Owned(msg.sender) {
        signer = _signer;
        treasury = _treasury;
        maxSupply = _maxSupply;
        price = _price;
        initiation = _initiation;
        baseURI = _baseURI;

        _setDefaultRoyalty(_treasury, DEFAULT_ROYALTY_BPS);
        _registerForOperatorFiltering();
    }

    /**
     * @notice Reverts if the queried token does not exist
     */
    modifier exists(uint256 _tokenId) {
        if (_ownerOf[_tokenId] == address(0)) revert F_BadInput();

        _;
    }

    /**
     * @notice Set the ECDSA signer address
     */
    function setSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) revert F_BadInput();

        signer = _signer;
    }

    /**
     * @notice Set the treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert F_BadInput();

        treasury = _treasury;
        _setDefaultRoyalty(_treasury, DEFAULT_ROYALTY_BPS);
    }

    /**
     * @notice See {ERC2981}
     */
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /**
     * @notice See {_operatorFilteringEnabled}
     */
    function setOperatorFiltering(bool _operatorFiltering) external onlyOwner {
        operatorFiltering = _operatorFiltering;
    }

    /**
     * @notice Mint tokens with ECDSA signatures
     */
    function mint(
        uint256 _quantity,
        uint256 _permitted,
        uint256 _deadline,
        bytes calldata _signature
    ) external payable {
        if (_quantity > _permitted) revert F_ExceededPermitted();
        if (totalSupply_ + _quantity > maxSupply) revert F_ExceededMaxSupply();
        if (msg.value < price * _quantity) revert F_Underpaid();
        if (block.timestamp > _deadline) revert F_SignatureExpired();
        if (!_signatureValid(_permitted, _deadline, _signature)) revert F_SignatureInvalid();

        bytes32 signatureHash = keccak256(_signature);
        if (_signatureUsed(signatureHash)) revert F_SignatureUsed();
        signatures[signatureHash] = true;

        (bool sent, ) = treasury.call{value: msg.value}("");
        if (!sent) revert F_PaymentError();

        unchecked {
            for (uint256 i = 0; i < _quantity; i++) {
                uint256 tokenId = ++totalSupply_;
                _safeMint(msg.sender, tokenId);
                lastTransferred[tokenId] = block.timestamp;
            }
        }
    }

    /**
     * @notice See {ERC4907}
     */
    function setUser(
        uint256 _tokenId,
        address _user,
        uint64 _expires
    ) external exists(_tokenId) {
        if (_expires > 2**32 - 1) revert F_BadInput();

        address owner = _ownerOf[_tokenId];
        if (msg.sender != owner)
            if (!isApprovedForAll[owner][msg.sender])
                if (getApproved[_tokenId] != msg.sender) revert F_Forbidden();

        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        if (rentable.expires > block.timestamp) revert F_TokenInUse();

        rentables[_tokenId] = _packRentable(_user, uint32(_expires), rentable.rate);

        emit UpdateUser(_tokenId, _user, _expires);
    }

    /**
     * @notice See {ERC4907}
     */
    function userOf(uint256 _tokenId) external view exists(_tokenId) returns (address) {
        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        return rentable.expires < block.timestamp ? address(0) : rentable.user;
    }

    /**
     * @notice See {ERC4907}
     */
    function userExpires(uint256 _tokenId) external view exists(_tokenId) returns (uint256) {
        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        return rentable.expires < block.timestamp ? 0 : rentable.expires;
    }

    /**
     * @notice See {ERC4907Rentable}
     */
    function rateOf(uint256 _tokenId) external view exists(_tokenId) returns (uint256) {
        return _unpackedRentable(rentables[_tokenId]).rate;
    }

    /**
     * @notice See {ERC4907Rentable}
     */
    function rent(uint256 _tokenId, uint64 _duration)
        external
        payable
        exists(_tokenId)
        nonReentrant
    {
        if (_duration < MIN_RENTAL_DURATION) revert F_BadInput();
        if (_duration > MAX_RENTAL_DURATION) revert F_BadInput();

        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        if (rentable.rate == 0) revert F_TokenNotAvailable();
        if (rentable.expires > block.timestamp) revert F_TokenInUse();

        uint256 rent_ = rentable.rate * _duration;
        if (msg.value < rent_) revert F_Underpaid();

        uint256 expires = block.timestamp + _duration;
        if (expires > 2**32 - 1) revert F_BadInput();

        // Rent distribution also conforms to the ERC2981 standard
        (address receiver, uint256 amount) = royaltyInfo(_tokenId, msg.value);
        (bool sent, ) = receiver.call{value: amount}("");
        if (!sent) revert F_PaymentError();

        address owner = _ownerOf[_tokenId];
        (sent, ) = owner.call{value: msg.value - amount}("");
        if (!sent) revert F_PaymentError();

        rentables[_tokenId] = _packRentable(msg.sender, uint32(expires), rentable.rate);

        emit UpdateUser(_tokenId, msg.sender, uint64(expires));
    }

    /**
     * @notice See {ERC4907Rentable}
     */
    function setRate(uint256 _tokenId, uint256 _rate) external exists(_tokenId) {
        if (_rate > 2**64 - 1) revert F_BadInput();
        if (_rate < MIN_RENTAL_RATE) revert F_BadInput();

        address owner = _ownerOf[_tokenId];
        if (msg.sender != owner)
            if (!isApprovedForAll[owner][msg.sender])
                if (getApproved[_tokenId] != msg.sender) revert F_Forbidden();

        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        if (rentable.expires > block.timestamp) revert F_TokenInUse();

        rentables[_tokenId] = _packRentable(rentable.user, rentable.expires, uint64(_rate));

        emit UpdateRate(_tokenId, _rate);
    }

    /**
     * @notice See {ERC721Metadata}
     */
    function setBaseURI(string calldata _uri) external onlyOwner {
        if (bytes(_uri).length == 0) revert F_BadInput();

        baseURI = _uri;
    }

    /**
     * @notice See {ERC721Metadata}
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        exists(_tokenId)
        returns (string memory)
    {
        if (bytes(baseURI).length == 0) return "";

        string memory id = _tokenId.toString();
        uint256 since = lastTransferred[_tokenId];
        string memory level = (block.timestamp - since) < initiation ? "Silver" : "Black";
        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);

        /* prettier-ignore */
        string memory encoded = Base64.encode(bytes(string(abi.encodePacked(
            /* solhint-disable */
            '{"name":"', name, ' #', id, '","image":"', baseURI, level, '.png",'
            '"animation_url":"', baseURI, level, '.mp4",'
            '"attributes":[{"trait_type":"Level","value":"', level, '"},',
            rentable.rate > 0 && rentable.expires < block.timestamp ? '{"value":"Rentable"},' : '',
            '{"display_type":"date","trait_type":"Member Since","value":', since.toString(), '}]}'
            /* solhint-enable */
        ))));

        return string(abi.encodePacked("data:application/json;base64,", encoded));
    }

    /**
     * @notice Query when did the membership start
     */
    function memberSince(uint256 _tokenId) public view exists(_tokenId) returns (uint256) {
        return lastTransferred[_tokenId];
    }

    /**
     * @notice See {ERC721Enumerable}
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @notice See {ERC721}
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        ERC721.transferFrom(_from, _to, _tokenId);
        lastTransferred[_tokenId] = block.timestamp;
    }

    /**
     * @notice See {ERC165}
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId) ||
            _interfaceId == type(IERC4907).interfaceId ||
            _interfaceId == type(IERC4907Rentable).interfaceId;
    }

    /**
     * @notice Read packed {Rentable} data from uint256
     */
    function _unpackedRentable(uint256 _packed) internal pure returns (Rentable memory rentable) {
        rentable.user = address(uint160(_packed));
        rentable.expires = uint32(_packed >> BITPOS_EXPIRES);
        rentable.rate = uint64(_packed >> BITPOS_RATE);
    }

    /**
     * @notice Pack {Rentable} data into uint256
     */
    function _packRentable(
        address _user,
        uint32 _expires,
        uint64 _rate
    ) internal pure returns (uint256 result) {
        assembly {
            // In case the upper bits somehow aren't clean
            _user := and(_user, BITMASK_USER)
            _expires := and(_expires, BITMASK_EXPIRES)
            // `_user` | (`_expires` << BITPOS_EXPIRES) | (`_rate` << BITPOS_RATE)
            result := or(_user, or(shl(BITPOS_EXPIRES, _expires), shl(BITPOS_RATE, _rate)))
        }
    }

    /**
     * @notice Validate ECDSA signatures
     */
    function _signatureValid(
        uint256 _permitted,
        uint256 _deadline,
        bytes calldata _signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _permitted, _deadline));
        address signer_ = ECDSA.recover(hash, _signature);
        return signer_ == signer ? true : false;
    }

    /**
     * @notice Check if an ECDSA signature has been used
     */
    function _signatureUsed(bytes32 _signatureHash) internal view returns (bool) {
        return signatures[_signatureHash];
    }

    /**
     * @dev For context, OpenSea has turned off royalties (yet they still
     * collect their 2.5% platform fees) on new collections that don't block
     * optional royalty marketplaces. As creators we unfortunately have to
     * follow the rule set by OpenSea since they still dominate the market at
     * the moment.
     *
     * This overhead adds ~3k gas to each {transferFrom} call 🖕
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFiltering;
    }
}