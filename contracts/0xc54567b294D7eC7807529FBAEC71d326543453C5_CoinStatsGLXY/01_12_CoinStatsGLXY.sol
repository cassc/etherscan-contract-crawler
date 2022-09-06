// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SignatureHelper.sol";

contract CoinStatsGLXY is ERC721, Ownable, SignatureHelper {
    using Strings for uint256;

    uint16 public totalSupply;
    uint16 private _maxSupply = 10000;

    // Mapping from {wallet address} to {nonce}
    mapping(address => uint16) public nonces;
    // Mapping from {interval index} to {minted token amount}
    mapping(uint256 => uint16) private _intervals;

    event Mint(
        address indexed account,
        uint256 tokenId,
        uint256 nonce,
        bytes signature
    );

    constructor(address _signer)
        ERC721("CoinStatsGLXY", "GLXY")
        SignatureHelper(_signer)
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmQyhH7CWpcRpZtuau7GzucbG4NnG2Uv3ZuAuvHGJWdys7/";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _getMessageHash(address account, uint256 nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, nonce));
    }

    /// @notice Generates random uint from signature
    function _getId(bytes calldata signature)
        internal
        pure
        returns (uint256 id)
    {
        return uint256(keccak256(signature)) % 10000;
    }

    /// @notice Returns any non empty interval
    function _getInterval(uint256 _index)
        private
        view
        returns (uint256 intervalIndex)
    {
        while (_intervals[_index] == 100) {
            _index++;
            if (_index == 100) {
                _index = 0;
            }
        }

        return _index;
    }

    /// @notice Mints NFT using signature
    function mint(bytes calldata signature) external {
        require(totalSupply < _maxSupply, "Mint limit is exceeded");
        bytes32 messageHash = _getMessageHash(msg.sender, nonces[msg.sender]++);
        require(
            verify(messageHash, signature),
            "Invalid signature, please contact our support team"
        );

        uint256 tokenId = _getId(signature) + 1;
        uint256 intervalIndex = tokenId / 100;

        if (_exists(tokenId)) {
            if (_intervals[intervalIndex] != 100) {
                while (tokenId != intervalIndex * 100 + 99) {
                    tokenId++;
                    if (!_exists(tokenId)) {
                        break;
                    }
                }

                if (_exists(tokenId)) {
                    tokenId = intervalIndex == 0
                        ? intervalIndex + 1
                        : intervalIndex * 100;

                    while (_exists(tokenId)) {
                        tokenId++;
                    }
                }
            } else {
                intervalIndex = _getInterval(intervalIndex);
                tokenId = intervalIndex * 100;

                while (_exists(tokenId)) {
                    tokenId++;
                }
            }
        }

        _mint(msg.sender, tokenId);
        _intervals[intervalIndex]++;
        totalSupply++;

        emit Mint(msg.sender, tokenId, nonces[msg.sender] - 1, signature);
    }
}