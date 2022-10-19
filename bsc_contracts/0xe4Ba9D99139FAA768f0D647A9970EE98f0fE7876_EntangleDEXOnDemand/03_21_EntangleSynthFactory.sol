// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.15;

import "./EntangleSynth.sol";
import "./PausableAccessControl.sol";
import "hardhat/console.sol";

/** @dev Contract that manages synth tokens */
contract EntangleSynthFactory is PausableAccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINT_ROLE = keccak256("MINT");

    event CreatedSynth(address synth);

    mapping(uint256 => mapping(address => mapping(uint256 => EntangleSynth))) public synths; // chainId -> synthChef -> pid

    constructor() {
        _setRoleAdmin(MINT_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /** @dev Creates smart contract of SynthToken and sets specific `_pid`
     *
     * Requirements:
     * - `_pid` there must be an pid of the created token
     * - the caller must have ``role``'s admin role.
     */
    function createSynth(uint256 _chainId, address _synthChef, uint256 _pid, IERC20 _opToken)
        external
        onlyRole(ADMIN_ROLE)
        whenNotPaused
        returns (EntangleSynth synth)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(_chainId, _synthChef, _pid)
        );
        synth = new EntangleSynth{salt: salt}(_chainId, _synthChef, _pid, _opToken);
        //save somewhere
        synths[_chainId][_synthChef][_pid] = synth;
        synth.grantRole(synth.ADMIN_ROLE(), msg.sender);
        emit CreatedSynth(address(synth));
    }

    function previewSynthAddress(uint256 _chainId, address _synthChef, uint256 _pid, IERC20 _opToken)
        public
        view
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(_chainId, _synthChef, _pid)
        );
        bytes memory bytecode = abi.encodePacked(type(EntangleSynth).creationCode);
        bytecode = abi.encodePacked(bytecode, abi.encode(_chainId, _synthChef, _pid, _opToken));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    /** @dev Creates `_amount` of SynthTokens with a specific id and assigns them to `_to`, increasing
     * the total supply.
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - `_pid` must be an pid of the created token
     */
    function mint(
        uint256 _chainId,
        address _synthChef,
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external onlyRole(MINT_ROLE) whenNotPaused {
        EntangleSynth synth = synths[_chainId][_synthChef][_pid];
        EntangleSynth(synth).mint(_to, _amount);
    }

    /**
     * @dev Destroys `_amount` tokens from `_from`, reducing the
     * total supply.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_from` must have at least `amount` tokens.
     * - `_pid` must be an pid of the created token
     */
    function burn(
        uint256 _chainId,
        address _synthChef,
        uint256 _pid,
        uint256 _amount,
        address _from
    ) external onlyRole(MINT_ROLE) whenNotPaused {
        EntangleSynth synth = synths[_chainId][_synthChef][_pid];
        EntangleSynth(synth).burn(_from, _amount);
    }
}