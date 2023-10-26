// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig} from "../libraries/HeyMintStorage.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract HeyMintERC1155ExtensionC is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;
    using ECDSAUpgradeable for bytes32;

    // ============ PRESALE ============

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(
        address _presaleSignerAddress
    ) external onlyOwner {
        require(_presaleSignerAddress != address(0));
        HeyMintStorage.state().cfg.presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     */
    function verifySignerAddress(
        bytes32 _messageHash,
        bytes calldata _signature
    ) private view returns (bool) {
        address presaleSignerAddress = HeyMintStorage
            .state()
            .cfg
            .presaleSignerAddress;
        return
            presaleSignerAddress ==
            _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Returns the presale price in wei. Presale price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function presalePriceInWei(uint16 _tokenId) public view returns (uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return uint256(state.tokens[_tokenId].presalePrice) * 10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow presale minting for a given token
     */
    function setTokenPresaleState(
        uint16 _tokenId,
        bool _presaleActiveState
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].presaleActive = _presaleActiveState;
    }

    /**
     * @notice Update the presale mint price for a given token
     */
    function setTokenPresalePrice(
        uint16 _tokenId,
        uint32 _presalePrice
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].presalePrice = _presalePrice;
    }

    function setTokenPresaleMaxSupply(
        uint16 _tokenId,
        uint16 _maxSupply
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _maxSupply >= state.data.totalSupply[_tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        state.tokens[_tokenId].presaleMaxSupply = _maxSupply;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given address for a given token
     */
    function setTokenPresaleMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].presaleMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint for a given token
     */
    function setTokenPresaleStartTime(
        uint16 _tokenId,
        uint32 _presaleStartTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_presaleStartTime > block.timestamp, "TIME_IN_PAST");
        state.tokens[_tokenId].presaleStartTime = _presaleStartTime;
    }

    /**
     * @notice Update the end time for public mint for a given token
     */
    function setTokenPresaleEndTime(
        uint16 _tokenId,
        uint32 _presaleEndTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_presaleEndTime > block.timestamp, "TIME_IN_PAST");
        require(
            state.tokens[_tokenId].presaleStartTime < _presaleEndTime,
            "END_TIME_BEFORE_START_TIME"
        );
        state.tokens[_tokenId].presaleEndTime = _presaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times for a given token
     */
    function setTokenUsePresaleTimes(
        uint16 _tokenId,
        bool _usePresaleTimes
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].usePresaleTimes = _usePresaleTimes;
    }

    /**
     * @notice Returns if public sale times are active for a given token
     */
    function tokenPresaleTimeIsActive(
        uint16 _tokenId
    ) public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.tokens[_tokenId].usePresaleTimes == false) {
            return true;
        }
        return
            block.timestamp >= state.tokens[_tokenId].presaleStartTime &&
            block.timestamp <= state.tokens[_tokenId].presaleEndTime;
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        bytes32 _messageHash,
        bytes calldata _signature,
        uint16 _tokenId,
        uint16 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        TokenConfig storage tokenConfig = state.tokens[_tokenId];
        uint256 heymintFee = _numTokens * heymintFeePerToken();
        uint256 presalePrice = presalePriceInWei(_tokenId);

        require(tokenConfig.presaleActive, "PRESALE_IS_NOT_ACTIVE");
        require(
            tokenPresaleTimeIsActive(_tokenId),
            "PRESALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            !state.data.tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        uint16 presaleMintsAllowedPerAddress = tokenConfig
            .presaleMintsAllowedPerAddress;
        uint16 newTokensMintedByAddress = state.data.tokensMintedByAddress[
            msg.sender
        ][_tokenId] + _numTokens;
        require(
            presaleMintsAllowedPerAddress == 0 ||
                newTokensMintedByAddress <= presaleMintsAllowedPerAddress,
            "MAX_MINTS_PER_ADDRESS_EXCEEDED"
        );
        require(
            _maximumAllowedMints == 0 ||
                newTokensMintedByAddress <= _maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        uint16 newTotalSupply = state.data.totalSupply[_tokenId] + _numTokens;
        require(
            state.tokens[_tokenId].maxSupply == 0 ||
                newTotalSupply <= state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint16 presaleMaxSupply = tokenConfig.presaleMaxSupply;
        require(
            presaleMaxSupply == 0 || newTotalSupply <= presaleMaxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == presalePrice * _numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            keccak256(abi.encode(msg.sender, _maximumAllowedMints, _tokenId)) ==
                _messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(_messageHash, _signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "HeyMint fee transfer failed");
        }

        state.data.tokensMintedByAddress[msg.sender][
            _tokenId
        ] = newTokensMintedByAddress;
        state.data.totalSupply[_tokenId] = newTotalSupply;

        _mint(msg.sender, _tokenId, _numTokens, "");

        if (presaleMaxSupply != 0 && newTotalSupply == presaleMaxSupply) {
            state.tokens[_tokenId].presaleActive = false;
        }
    }
}