// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./utils/ERC721/ERC721Claimable.sol";
import "./utils/libs/IERC20.sol";

contract UniqCollections is ERC721Claimable {
    // ----- VARIABLES ----- //
    uint256 internal _tokenNum;
    mapping(address => bool) internal _isPrizeCollectedForAddress;
    address internal _vestingAddress;
    address internal _vestingAddress2;
    address internal _tokenAddress;

    // ----- MODIFIERS ----- //
    modifier notZeroAddress(address a) {
        require(a != address(0), "ZERO address can not be used");
        _;
    }

    // ----- EVENTS ----- //
    event MintedFromVesting(address _minter, uint256 _tokenId, uint256 _type);
    event MintedFromVesting2(address _minter, uint256 _tokenId, uint256 _type);

    // ----- CONSTRUCTOR ----- //
    constructor(
        address _proxyRegistryAddress,
        string memory _name,
        string memory _symbol,
        string memory _ttokenUri,
        address _vestingAddr,
        address _vestingAddr2,
        address _tokenAddr,
        address _claimingAddr,
        uint _royaltyFee
    )
        notZeroAddress(_proxyRegistryAddress)
        ERC721Claimable(_name, _symbol, _ttokenUri, _proxyRegistryAddress, _claimingAddr, _royaltyFee)
    {
        _vestingAddress = _vestingAddr;
        _vestingAddress2 = _vestingAddr2;
        _tokenAddress = _tokenAddr;
        _initialMint();
    }

    // ----- VIEWS ----- //
    function isPrizeCollectedForAddress(address _address)
        external
        view
        returns (bool)
    {
        return _isPrizeCollectedForAddress[_address];
    }

    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function contractURI() public pure returns (string memory) {
        return "https://uniqly.io/api/nft-collections/";
    }

    // ----- PRIVATE METHODS ----- //
    function _initialMint() internal onlyOwner{
        address _addr1 = 0x553b6C7321bE6c7C8C6A9dC68E241F50c2eDec20;
        address _addr2 = 0x3DBE4C57da3919760dAB85Ff484d3a14B604f1F4;
        address _addr3 = 0xDAE6cA75bB2aFD213E5887513D8b1789122EaAea;
        _isPrizeCollectedForAddress[_addr1] = true;
        _safeMint(_addr1, 0);
        emit MintedFromVesting(_addr1, 0, 1);
        _isPrizeCollectedForAddress[_addr2] = true;
        _safeMint(_addr2, 1);
        emit MintedFromVesting(_addr2, 1, 1);
        _isPrizeCollectedForAddress[_addr3] = true;
        _safeMint(_addr3, 2);
        emit MintedFromVesting(_addr3, 2, 1);
        _tokenNum = 3;
    }
    
    // ----- PUBLIC METHODS ----- //
    function mintSelectedIdFor(
        uint256 _id,
        uint256 _price,
        bytes memory _signature,
        address _receiver
    ) external {
        require(verifySignature(_id, _price, _signature), "Signature mismatch");
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _price
            )
        );
        _safeMint(_receiver, _id);
    }

    function mintFromVesting() external {
        require(
            !_isPrizeCollectedForAddress[msg.sender],
            "Prize is already collected"
        );
        uint256 bonus = Vesting(_vestingAddress).bonus(msg.sender);
        uint256 bonus2 = Vesting(_vestingAddress2).bonus(msg.sender);
        require(bonus > 0 || bonus2 > 0, "Bonus not found");
        _isPrizeCollectedForAddress[msg.sender] = true;
        if (bonus > 0) {
            _safeMint(msg.sender, _tokenNum);
            emit MintedFromVesting(msg.sender, _tokenNum, bonus);
            _tokenNum++;
        }
        if (bonus2 > 0) {
            _safeMint(msg.sender, _tokenNum);
            emit MintedFromVesting2(msg.sender, _tokenNum, bonus2);
            _tokenNum++;
        }
    }

    // ----- MESSAGE SIGNATURE ----- //
    /// @dev not test for functions related to signature
    function getMessageHash(uint256 _tokenId, uint256 _price)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenId, _price));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /// @dev not test for functions related to signature
    function verifySignature(
        uint256 _tokenId,
        uint256 _price,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_tokenId, _price);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    /// @dev not test for functions related to signature
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // ----- OWNERS METHODS ----- //
    function mintAsOwner(uint256 _tokenNumber, address _receiver)
        external
        onlyOwner
    {
        _safeMint(_receiver, _tokenNumber);
    }

    function editRoyaltyFee(uint256 _newFee) external onlyOwner {
        ROYALTY_FEE = _newFee;
    }

    function editTokenAddress(address _newTokenAddress) external onlyOwner {
        _tokenAddress = _newTokenAddress;
    }

    function batchMintAsOwner(
        uint256 _tokenNumber,
        uint256 _elements,
        address _receiver
    ) external onlyOwner {
        uint256 i = 0;
        for (i = 0; i < _elements; i++) {
            _safeMint(_receiver, _tokenNumber + i);
        }
    }

     function batchMintSelectedIds(
        uint[] memory _ids,
        address[] memory _addresses
    ) external onlyOwner {
        uint len = _ids.length;
        require(len == _addresses.length, "Arrays length");
        uint256 i = 0;
        for (i = 0; i < len; i++) {
            _safeMint(_addresses[i], _ids[i]);
        }
    }

    function editTokenUri(string memory _ttokenUri) external onlyOwner {
        _token_uri = _ttokenUri;
    }

    function recoverERC20(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }
}

interface Ierc20 {
    function transfer(address, uint256) external;
}

interface Vesting {
    function bonus(address user) external view returns (uint256);
}