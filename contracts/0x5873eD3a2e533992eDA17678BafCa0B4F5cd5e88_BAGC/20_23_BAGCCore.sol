// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BAGCCore is OwnableUpgradeable {
    using ECDSA for bytes32;

    string public baseURI;
    address public invitationNFTAddress;
    address public merchNFTAddress;

    address internal relayerAddress;
    uint256 internal _numUserAvailableTokens;
    uint256 internal _userTokenBoundaries;

    // Mapping from tokenID to end of locking status
    mapping(uint256 => uint256) _locked;
    mapping(uint256 => uint256) internal _availableTokens;

    /**
     * ==================
     * setting value
     * ==================
     */

    /// @dev the function to get the address of relayer
    function getRelayerAddress() public view onlyOwner returns (address) {
        return relayerAddress;
    }

    /// @dev the function to update the baseURI
    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /// @dev the function to update the relayerAddress
    function updateRelayerAddress(address relayerAddress_) public onlyOwner {
        relayerAddress = relayerAddress_;
    }

    /// @dev the function to update the updateMerchNFTAddress
    function updateMerchNFTAddress(address merchNFTAddress_) public onlyOwner {
        merchNFTAddress = merchNFTAddress_;
    }

    /// @dev the function to update the userTokenBoundaries
    function updateBoundaries(uint256 boundaries) public onlyOwner {
        _userTokenBoundaries = boundaries;
    }

    /**
     * ==================
     * random logic
     * ==================
     */

    /// @dev the function to get the random token id
    function getRandomAvailableTokenId(address to, uint256 expiredAt) internal returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encodePacked(
                    uint160(relayerAddress),
                    uint160(address(this)),
                    uint256(block.timestamp),
                    uint256(block.number),
                    uint256(_userTokenBoundaries),
                    uint160(to),
                    uint256(expiredAt),
                    uint256(_numUserAvailableTokens)
                )
            )
        );
        uint256 randomIndex = (randomNum) % _numUserAvailableTokens;

        uint256 availableIndex = getAvailableTokenAtIndex(randomIndex);
        return getRealTokenId(availableIndex);
    }

    /// @dev the function to get the available token id
    function getAvailableTokenAtIndex(uint256 indexToUse) internal returns (uint256) {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            result = indexToUse;
        } else {
            result = valAtIndex;
        }

        uint256 lastIndex = _numUserAvailableTokens - 1;
        uint256 lastValInArray = _availableTokens[lastIndex];
        if (indexToUse != lastIndex) {
            if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex;
            } else {
                _availableTokens[indexToUse] = lastValInArray;
            }
        }
        if (lastValInArray != 0) {
            delete _availableTokens[lastIndex];
        }

        return result;
    }

    function getNumUserAvailableTokens() public view returns (uint256) {
        return _numUserAvailableTokens;
    }

    /// @dev the function to get the real token id
    function getRealTokenId(uint256 tempTokenId) internal view returns (uint256) {
        if (0 <= tempTokenId && tempTokenId <= 6) {
            return (_userTokenBoundaries & 0xffff) + tempTokenId;
        } else if (6 < tempTokenId && tempTokenId <= 14) {
            return ((_userTokenBoundaries >> 16) & 0xffff) + tempTokenId - 7;
        } else if (14 < tempTokenId && tempTokenId <= 254) {
            return ((_userTokenBoundaries >> (16 * 2)) & 0xffff) + tempTokenId - 15;
        } else if (254 < tempTokenId && tempTokenId <= 1019) {
            return ((_userTokenBoundaries >> (16 * 3)) & 0xffff) + tempTokenId - 255;
        } else if (1019 < tempTokenId && tempTokenId <= 2487) {
            return ((_userTokenBoundaries >> (16 * 4)) & 0xffff) + tempTokenId - 1020;
        } else {
            return ((_userTokenBoundaries >> (16 * 5)) & 0xffff) + tempTokenId - 2488;
        }
    }

    /// @notice the function used to check if the token is a user token
    /// @param tokenId the token id to check
    function isUserToken(uint256 tokenId) public view returns (bool) {
        return
            (_userTokenBoundaries & 0xffff <= tokenId &&
                tokenId <= (_userTokenBoundaries & 0xffff) + 6) ||
            ((_userTokenBoundaries >> 16) & 0xffff <= tokenId &&
                tokenId <= ((_userTokenBoundaries >> 16) & 0xffff) + 7) ||
            ((_userTokenBoundaries >> (16 * 2)) & 0xffff <= tokenId &&
                tokenId <= ((_userTokenBoundaries >> (16 * 2)) & 0xffff) + 239) ||
            ((_userTokenBoundaries >> (16 * 3)) & 0xffff <= tokenId &&
                tokenId <= ((_userTokenBoundaries >> (16 * 3)) & 0xffff) + 764) ||
            ((_userTokenBoundaries >> (16 * 4)) & 0xffff <= tokenId &&
                tokenId <= ((_userTokenBoundaries >> (16 * 4)) & 0xffff) + 1467) ||
            ((_userTokenBoundaries >> (16 * 5)) & 0xffff <= tokenId &&
                tokenId <= ((_userTokenBoundaries >> (16 * 5)) & 0xffff) + 2399);
    }

    /**
     * ==================
     * internal
     * ==================
     */

    /// @notice the function used to verify the signature
    /// @param invitationTokenId The tokenId of the invitation NFT.
    /// @param relayerSignature The signature of the relayer.
    /// @param expiredAt The timestamp of the signature expired.
    function verifySignature(
        uint256 invitationTokenId,
        bytes memory relayerSignature,
        uint256 expiredAt
    ) internal view returns (bool success, string memory message) {
        bytes32 recoveredHash = keccak256(abi.encodePacked(invitationTokenId, expiredAt));

        bytes32 recoverSigOrigin = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", recoveredHash)
        );

        address recoverRelayerSigner = recoverSigOrigin.recover(relayerSignature);

        if (recoverRelayerSigner != relayerAddress) {
            return (success = false, message = "BAGC: Invalid relayer signer");
        }

        success = true;
    }

    uint256[42] private __gap;
}