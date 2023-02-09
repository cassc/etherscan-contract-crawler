// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IGameLoot.sol";

interface IEquipment {
    function mint(address reciever, uint256 amount) external payable;

    function setRevealed(uint256 tokenID) external;

    function totalSupply() external view returns (uint256);
}

contract GameLootGameMinter is Pausable {
    address public equipment;

    // Access control
    address public timeLocker;
    address public controller;

    mapping(address => bool) public signers;
    mapping(uint256 => bool) public usedNonce;

    // tokenID => eqID
    mapping(uint256 => uint256) private eqIDs;
    mapping(uint256 => bool) private eqExist;

    event GameMint(
        address user,
        address equipment,
        uint256 tokenID,
        uint256 eqID,
        uint256 nonce
    );

    constructor(
        address equipment_,
        address timeLocker_,
        address controller_,
        address[] memory signers_
    ) {
        equipment = equipment_;
        timeLocker = timeLocker_;
        controller = controller_;
        for (uint256 i; i < signers_.length; i++) signers[signers_[i]] = true;
    }

    /* ---------------- game mint ---------------- */

    /// @notice Mint from game
    /// @dev Need to sign
    function gameMint(
        uint256 nonce_,
        uint256 eqID_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) public whenNotPaused {
        require(!usedNonce[nonce_], "nonce is used");
        require(!eqIDExist(eqID_), "this eqID is already exists");
        require(attrIDs_.length == attrValues_.length, "param length error");
        require(
            verify(
                msg.sender,
                address(this),
                nonce_,
                eqID_,
                attrIDs_,
                attrValues_,
                signature_
            ),
            "sign is not correct"
        );
        usedNonce[nonce_] = true;

        uint256 tokenID = IEquipment(equipment).totalSupply();
        IGameLoot(equipment).attachBatch(tokenID, attrIDs_, attrValues_);

        eqIDs[tokenID] = eqID_;
        eqExist[eqID_] = true;

        IEquipment(equipment).mint(msg.sender, 1);
        IEquipment(equipment).setRevealed(tokenID);
        emit GameMint(msg.sender, equipment, tokenID, eqID_, nonce_);
    }

    function verify(
        address wallet_,
        address contract_,
        uint256 nonce_,
        uint256 eqID_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) internal view returns (bool) {
        return
            signers[
                signatureWallet(
                    wallet_,
                    contract_,
                    nonce_,
                    eqID_,
                    attrIDs_,
                    attrValues_,
                    signature_
                )
            ];
    }

    function signatureWallet(
        address wallet_,
        address contract_,
        uint256 nonce_,
        uint256 eqID_,
        uint128[] memory attrIDs_,
        uint128[] memory attrValues_,
        bytes memory signature_
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encode(wallet_, contract_, nonce_, eqID_, attrIDs_, attrValues_)
        );

        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature_);
    }

    function eqIDExist(uint256 eqID) public view returns (bool) {
        return eqExist[eqID];
    }

    function queryEqIDByTokenID(uint256 tokenID) public view returns (uint256) {
        return eqIDs[tokenID];
    }

    /* ---------------- timelocker ---------------- */

    function setSigner(address signer, bool isOk) public onlyTimelocker {
        signers[signer] = isOk;
    }

    function setTimeLocker(address timeLocker_) public onlyTimelocker {
        timeLocker = timeLocker_;
    }

    modifier onlyTimelocker() {
        require(msg.sender == timeLocker, "not timelocker");
        _;
    }

    /* ---------------- controller ---------------- */

    function pause() public onlyController {
        _pause();
    }

    function unpause() public onlyController {
        _unpause();
    }

    function transferController(address newController) public onlyController {
        controller = newController;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Permission denied");
        _;
    }
}