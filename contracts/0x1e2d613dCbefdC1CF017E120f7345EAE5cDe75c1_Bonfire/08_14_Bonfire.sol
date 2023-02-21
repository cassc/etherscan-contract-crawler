// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/extension/Permissions.sol";
import "@thirdweb-dev/contracts/openzeppelin-presets/security/ReentrancyGuard.sol";
import "@thirdweb-dev/contracts/openzeppelin-presets/utils/cryptography/EIP712.sol";
import "./extensions/Pausable.sol";
import "./interfaces/IBonfire.sol";

import "./interfaces/original/IOldWorldPass.sol"; // old WP
import "./interfaces/original/IOldDiceNFT.sol"; // old Dice
import "./interfaces/IDiceNFT.sol"; // new Dice
import "./interfaces/IWorldPassNFT.sol"; // new WP

contract Bonfire is EIP712, ReentrancyGuard, Pausable, Permissions, IBonfire {
    using ECDSA for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256(
            "BurnRequest(address to,uint128 wpBurnAmount,uint256[] diceIds,uint8[] diceResults,uint8[] wpHouses,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Mapping from burn request UID => whether the request is processed.
    mapping(bytes32 => bool) private requestIdProcessed;

    address public allowedSigner;

    address public immutable originalDice;
    address public immutable originalWP;
    address public immutable reforgedDice;
    address public immutable reforgedWP;

    IOldWorldPass internal immutable oldWP;
    IOldDiceNFT internal immutable oldDice;
    IDiceNFT internal immutable newDice;
    IWorldPassNFT internal immutable newWP;

    // Allows pausing/unpausing
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        address _originalDice,
        address _originalWP,
        address _reforgedDice,
        address _reforgedWP,
        address _allowedSigner
    ) EIP712("Bonfire", "1") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        allowedSigner = _allowedSigner;

        originalDice = _originalDice;
        originalWP = _originalWP;
        reforgedDice = _reforgedDice;
        reforgedWP = _reforgedWP;

        oldWP = IOldWorldPass(originalWP);
        oldDice = IOldDiceNFT(originalDice);
        newDice = IDiceNFT(reforgedDice);
        newWP = IWorldPassNFT(reforgedWP);
    }

    /*//////////////////////////////////////////////////////////////
                        Our custom logic
    //////////////////////////////////////////////////////////////*/

    function bonfireBurn(BurnRequest calldata _req, bytes calldata _signature)
        external
        nonReentrant
        whenNotPaused
        returns (address signer)
    {
        require(
            _req.wpBurnAmount == _req.wpHouses.length,
            "Unequal wpBurnAmount & wpHouses"
        );

        require(
            _req.wpBurnAmount > 0 || _req.diceIds.length > 0,
            "Nothing to burn"
        );

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        // Burn the requested amount of original WPs
        // User needs to first approveAll on original WP for this Bonfire contract
        if (_req.wpBurnAmount > 0) {
            oldWP.burn(_req.to, 0, _req.wpBurnAmount);
        }

        // Burn the requested original dice NFTs & ensure req.to is the owner of the diceIDs
        // User needs to first approveAll on original Dice for this Bonfire contract
        uint256 diceBurnAmount = _req.diceIds.length;
        for (uint256 i = 0; i < diceBurnAmount; ) {
            if (oldDice.ownerOf(_req.diceIds[i]) != _req.to) {
                revert("Only the owner of the dice can burn them");
            }

            oldDice.burn(_req.diceIds[i]);

            unchecked {
                ++i;
            }
        }

        // Mint the new WP NFTs
        for (uint256 i = 0; i < _req.wpHouses.length; ) {
            newWP.mintWithHouseTo(_req.to, House(_req.wpHouses[i]));

            unchecked {
                ++i;
            }
        }

        // Mint the new Dice NFTs
        if (diceBurnAmount > 0) {
            if (diceBurnAmount == 1) {
                newDice.mint(_req.to, _req.diceIds[0]);
            } else {
                newDice.batchMint(_req.to, _req.diceIds);
            }
        }

        emit BonfireBurn(_req.to, _req);
    }

    /**
     *  @notice Allows caller to burn their old dice to mint new ones.
     *
     *  @param diceIds The diceIds to burn & re-mint from new contract.
     */
    function burnDiceOnly(uint256[] calldata diceIds)
        external
        nonReentrant
        whenNotPaused
    {
        require(diceIds.length > 0, "Nothing to burn");

        // Burn the requested original dice NFTs
        // User needs to first approveAll on original Dice for this Bonfire contract
        uint256 diceBurnAmount = diceIds.length;
        for (uint256 i = 0; i < diceBurnAmount; ) {
            if (oldDice.ownerOf(diceIds[i]) != msg.sender) {
                revert("Only the owner of the dice can burn them");
            }

            oldDice.burn(diceIds[i]);

            unchecked {
                ++i;
            }
        }

        // Mint the new Dice NFTs
        if (diceBurnAmount == 1) {
            newDice.mint(msg.sender, diceIds[0]);
        } else {
            newDice.batchMint(msg.sender, diceIds);
        }

        emit BonfireBurnDiceOnly(msg.sender, diceIds);
    }

    /**
     *  @notice Allows caller to burn their old wp to mint new WPs with "Scarred" attribute.
     *
     *  @param burnAmount The amount of old WPs to burn & re-mint from new contract.
     */
    function joinScarred(uint256 burnAmount)
        external
        nonReentrant
        whenNotPaused
    {
        require(burnAmount > 0, "Cannot burn nothing");

        oldWP.burn(msg.sender, 0, burnAmount);

        if (burnAmount == 1) {
            newWP.mintWithHouseTo(msg.sender, House.Scarred);
        } else {
            newWP.batchMintWithHouseTo(msg.sender, burnAmount, House.Scarred);
        }

        emit BonfireJoinScarred(msg.sender, burnAmount);
    }

    function setAllowedSigner(address _allowedSigner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_allowedSigner != address(0), "allowedSigner undefined");

        allowedSigner = _allowedSigner;
    }

    /*//////////////////////////////////////////////////////////////
                        EIP712 related logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Verifies that a burn request is signed by an authorized account.
    function verify(BurnRequest calldata _req, bytes calldata _signature)
        public
        view
        returns (bool success, address signer)
    {
        signer = _recoverAddress(_req, _signature);
        success = !requestIdProcessed[_req.uid] && _canSignBurnRequest(signer);
    }

    /// @dev Returns whether a given address is authorized to sign burn requests.
    function _canSignBurnRequest(address _signer) internal view returns (bool) {
        return _signer == allowedSigner;
    }

    /// @dev Verifies a burn request and marks the request as processed.
    function _processRequest(
        BurnRequest calldata _req,
        bytes calldata _signature
    ) internal returns (address signer) {
        bool success;
        (success, signer) = verify(_req, _signature);

        if (!success) {
            revert("Invalid req");
        }

        if (
            _req.validityStartTimestamp > block.timestamp ||
            block.timestamp > _req.validityEndTimestamp
        ) {
            revert("Req expired");
        }
        require(_req.to != address(0), "recipient undefined");

        requestIdProcessed[_req.uid] = true;
    }

    /// @dev Returns the address of the signer of the burn request.
    function _recoverAddress(
        BurnRequest calldata _req,
        bytes calldata _signature
    ) internal view returns (address) {
        return
            _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(
                _signature
            );
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRequest(BurnRequest calldata _req)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                TYPEHASH,
                _req.to,
                _req.wpBurnAmount,
                keccak256(abi.encodePacked(_req.diceIds)),
                keccak256(abi.encodePacked(_req.diceResults)),
                keccak256(abi.encodePacked(_req.wpHouses)),
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid
            );
    }

    /*//////////////////////////////////////////////////////////////
                            Pausable Logic
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _unpause();
    }
}