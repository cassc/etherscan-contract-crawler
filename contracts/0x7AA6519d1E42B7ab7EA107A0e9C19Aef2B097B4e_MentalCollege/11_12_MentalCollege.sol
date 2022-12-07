// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SignatureChecker.sol";

contract MentalCollege is ERC721, ReentrancyGuard {
    address private _owner;

    address private _permitOwner;

    address private _recipient;

    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => mapping(bytes4 => uint128)) private _mintedNumber;

    //Mint Role => Allowed Mint Amount => Discount Factor
    mapping(bytes4 => uint256) private _mintInfo;

    uint256 public totalSupply;

    uint256 private _price;

    uint256 private _startIndex;

    uint256 private _timeSet;

    string private _baseTokenURI;

    bytes4 public constant PRIVILEGEROLENAME = 0x64730000;

    uint256 public constant COLLECTIONSIZE = 6000;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(
        address permitOwner_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                0x4726992d1c50f778516dd5a087ee7ccb94b41129cf51e555af6bb742a3ca7a4a,
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
                block.chainid,
                address(this)
            )
        );
        _owner = msg.sender;
        _permitOwner = permitOwner_;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier isMintOn() {
        require(
            isEarlyMint() || isPublicMint() || isDsMint(),
            "Mental: Mint Is Not On"
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) return _baseTokenURI;
        else return "Waiting...";
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    //Transfer Contract Ownership
    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    //Tranfer Signature Permit Ownership
    function transferPermitOwnership(address newPermitOwner)
        external
        onlyOwner
    {
        address oldPermitOwner = _permitOwner;
        _permitOwner = newPermitOwner;
        emit OwnershipTransferred(oldPermitOwner, newPermitOwner);
    }

    //Set Mint Role & Allowed Mint Count & Discount Factor
    function setMintRoleInfo(
        string[] memory roleNames,
        uint128[] memory allowedMintCounts,
        uint128[] memory discountFactors
    ) external onlyOwner {
        require(
            roleNames.length == allowedMintCounts.length &&
                allowedMintCounts.length == discountFactors.length,
            "Data Mismatch"
        );
        for (uint256 i = 0; i < roleNames.length; i++) {
            require(
                allowedMintCounts[i] > 0 && discountFactors[i] > 0,
                "Info Error"
            );
            _mintInfo[bytes4(bytes(roleNames[i]))] =
                uint256(allowedMintCounts[i]) |
                (uint256(discountFactors[i]) << 128);
        }
    }

    //Get Allowed Mint Number & Discount Factoe for Roles ["og","wh","ds"]
    function getRoleInfo(string calldata roleName)
        public
        view
        returns (uint128, uint128)
    {
        require(_mintInfo[bytes4(bytes(roleName))] > 0, "Limit Error");
        return (
            uint128(_mintInfo[bytes4(bytes(roleName))]),
            uint128(_mintInfo[bytes4(bytes(roleName))] >> 128)
        );
    }

    //Set Early Mint & Public Mint Time
    function setMintTime(
        uint48 dsMintStart,
        uint48 dsDuration,
        uint48 earlyMintStart,
        uint48 earlyDuration,
        uint32 publicMintStart,
        uint32 publicDuration
    ) external onlyOwner {
        require(
            dsMintStart > 0 &&
                earlyMintStart >= dsMintStart + dsDuration &&
                publicMintStart >= earlyMintStart + earlyDuration,
            "Mint Time Slots Not In Order"
        );
        _timeSet =
            uint256(dsMintStart) |
            (uint256(dsDuration) << 48) |
            (uint256(earlyMintStart) << 96) |
            (uint256(earlyDuration) << 144) |
            (uint256(publicMintStart) << 192) |
            (uint256(publicDuration) << 224);
    }

    //Get Mint Times & Price
    function getMintInfo()
        public
        view
        returns (SignatureInfo.InfoSet memory info)
    {
        info = SignatureInfo.InfoSet(
            uint48(_timeSet),
            uint48(_timeSet >> 48),
            uint48(_timeSet >> 96),
            uint48(_timeSet >> 144),
            uint32(_timeSet >> 192),
            uint32(_timeSet >> 224),
            _price
        );
    }

    //Set Public Mint Price & Recipient Of Funds
    function setMintPriceAndRecipient(uint256 price_, address recipient_)
        external
        onlyOwner
    {
        require(
            price_ > 0 && recipient_ != address(0x0),
            "Must be greater than 0"
        );
        _price = price_;
        _recipient = recipient_;
    }

    function isDsMint() internal view returns (bool) {
        SignatureInfo.InfoSet memory info = getMintInfo();
        return
            info.dsMintStart <= block.timestamp &&
            info.dsMintStart + info.dsDuration >= block.timestamp;
    }

    function isPublicMint() internal view returns (bool) {
        SignatureInfo.InfoSet memory info = getMintInfo();
        return
            info.publicMintStart <= block.timestamp &&
            info.publicMintStart + info.publicMintDuration >= block.timestamp;
    }

    function isEarlyMint() internal view returns (bool) {
        SignatureInfo.InfoSet memory info = getMintInfo();
        return
            info.earlyMintStart <= block.timestamp &&
            info.earlyMintStart + info.earlyMintDuration >= block.timestamp;
    }

    function validateContentSignature(SignatureInfo.Content calldata content)
        internal
        view
        returns (uint256)
    {
        require(
            SignatureChecker.verify(
                SignatureInfo.getContentHash(content),
                _permitOwner,
                content.v,
                content.r,
                content.s,
                DOMAIN_SEPARATOR
            ),
            "Authentication Fails"
        );

        if (isDsMint()) {
            require(
                bytes4(bytes(content.identity)) == PRIVILEGEROLENAME,
                "You Need DS Role For Privilege Mint"
            );
        }
        (uint128 amount, uint128 discountFactor) = getRoleInfo(
            content.identity
        );
        require(discountFactor > 0, "Discount Information Is Not Set");
        require(
            _mintedNumber[content.holder][bytes4(bytes(content.identity))] +
                content.amount <=
                amount,
            "Exceeds The Allowed Amount"
        );
        return (_price - (_price * discountFactor) / 100) * content.amount;
    }

    function getMintPrice(SignatureInfo.Content calldata content)
        public
        view
        returns (uint256)
    {
        if (isEarlyMint() || isDsMint())
            return validateContentSignature(content);
        else return content.amount * _price;
    }

    function batchMint(SignatureInfo.Content calldata content)
        external
        payable
        isMintOn
    {
        require(content.holder != address(0), "Zero Address");
        require(
            totalSupply + content.amount <= COLLECTIONSIZE,
            "Exceeds Collection Size"
        );
        uint256 mintCost = getMintPrice(content);
        require(msg.value >= mintCost && mintCost > 0, "Insufficient Fund");

        _safeTransferETH(_recipient, msg.value);
        for (uint256 i = 0; i < content.amount; i++) {
            _safeMint(content.holder, _startIndex);
            _startIndex++;
        }
        totalSupply += content.amount;
        if (isEarlyMint() || isDsMint())
            _mintedNumber[content.holder][
                bytes4(bytes(content.identity))
            ] += content.amount;
    }

    //Tranfer Fund To Wallet
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    function devMint(uint256 amount) external onlyOwner {
        require(amount > 0, "Mental: Quantity Should Be Bigger Than Zero.");
        require(
            totalSupply + amount <= COLLECTIONSIZE,
            "Mental: It Will Exceed Max Supply."
        );
        require(
            _recipient != address(0x0),
            "Mental: The Recipient Address Is Not Set"
        );
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_recipient, _startIndex);
            _startIndex++;
        }
        totalSupply += amount;
    }
}