// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMadMemberPass.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MadMemberPassSeller2nd is AccessControl, Ownable, Pausable {
    using ECDSA for bytes32;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";

    // SaleInfo
    IMadMemberPass public madMemberPass = IMadMemberPass(0x3F2B98BdE2DF37aB83c79696A3d3d691355c4fF8);
    address public withdrawAddress = 0x188C4B3A3F2263e47316182681749B3F9FF746f1;
    uint256 public maxSupply = 3000;
    uint256 public mintCost = 0.05 ether;
    uint256 public nonce = 0;
    address private signer;

    // Modifier
    modifier enoughEth(uint256 _amount) {
        require(mintCost > 0 && msg.value >= _amount * mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxSupply(uint256 _amount) {
        require(madMemberPass.getTotalSupply() + _amount <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier isValidSignature (address _to, uint256 _amount, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                _to,
                _amount,
                nonce
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }

    // Constructor
    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // Mint
    function mint(address _to, uint256 _amount, bytes calldata _signature) external payable
        whenNotPaused
        withinMaxSupply(_amount)
        enoughEth(_amount)
        isValidSignature(_to, _amount, _signature)
    {
        madMemberPass.mint(_to, _amount);
        nonce++;
    }

    // Getter
    function totalSupply() external view returns (uint256) {
        return madMemberPass.getTotalSupply();
    }

    // Setter
    function setMadMemberPass(address _address) external onlyRole(ADMIN) {
        madMemberPass = IMadMemberPass(_address);
    }
    function setWithdrawAddress(address _value) external onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setMaxSupply(uint256 _value) external onlyRole(ADMIN) {
        maxSupply = _value;
    }
    function setMintCost(uint256 _value) external onlyRole(ADMIN) {
        mintCost = _value;
    }
    function setSigner(address _value) external onlyRole(ADMIN) {
        signer = _value;
    }

    // withdraw
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }
}