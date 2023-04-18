// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../interfaces/IAgentManager.sol";

contract AgentManager is IAgentManager, Ownable2StepUpgradeable {
    /**
     * @dev Agent props
     */
    struct AgentProp {
        bool hasAgent;
        uint256 maxCredit;
        uint256 remainingCredit;
        uint256 effectiveBlock;
        uint256 expirationBlock;
        bool minable;
        bool burnable;
    }

    // agent map
    mapping(address => AgentProp) private _agents;

    modifier onlyAgent() {
        require(hasAgent(msg.sender), "AG000");
        _;
    }

    modifier onlyMinable() {
        require(isMinable(msg.sender), "AG002");
        _;
    }

    modifier onlyBurnable() {
        require(isBurnable(msg.sender), "AG003");
        _;
    }

    /**
     * @dev Return agent max credit
     */
    function getMaxCredit(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        return _agents[account].maxCredit;
    }

    /**
     * @dev Return agent remaining credit
     * @dev Return zero when the block number does not reach the effective block number or exceeds the expiration block number
     */
    function getRemainingCredit(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        if (_agents[account].effectiveBlock > block.number) {
            return 0;
        }
        if (_agents[account].expirationBlock < block.number) {
            return 0;
        }
        return _agents[account].remainingCredit;
    }

    /**
     * @dev Return agent minable status
     */
    function isMinable(address account) public view override returns (bool) {
        require(hasAgent(account), "AG000");
        return _agents[account].minable;
    }

    /**
     * @dev Return agent burnable status
     */
    function isBurnable(address account) public view override returns (bool) {
        require(hasAgent(account), "AG000");
        return _agents[account].burnable;
    }

    /**
     * @dev Return agent effective block number
     */
    function getEffectiveBlock(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        return _agents[account].effectiveBlock;
    }

    /**
     * @dev Return agent expiration block number
     */
    function getExpirationBlock(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        return _agents[account].expirationBlock;
    }

    /**
     * @dev Return whether the address is an agent
     */
    function hasAgent(address account) public view override returns (bool) {
        return _agents[account].hasAgent;
    }

    /**
     * @dev Grant the address as agent
     * @dev After setting credit, the max credit and the remaining credit are the same as credit
     * @param account Grant agent address
     * @param credit Grant agent Max credit & Remaining credit
     * @param effectiveBlock Agent effective block number
     * @param expirationBlock Agent expiration block number
     * @param minable Agent minable
     * @param burnable Agent burnable
     */
    function grantAgent(
        address account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable
    ) public override onlyOwner {
        require(account != address(0), "CE000");
        require(!hasAgent(account), "AG001");
        require(credit > 0, "AG005");
        require(expirationBlock > block.number, "AG006");
        require(effectiveBlock < expirationBlock, "AG015");
        _grantAgent(account, credit, effectiveBlock, expirationBlock, minable, burnable);
    }

    function _grantAgent(
        address account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable
    ) internal {
        _agents[account].hasAgent = true;
        _agents[account].maxCredit = credit;
        _agents[account].remainingCredit = credit;
        _agents[account].effectiveBlock = effectiveBlock;
        _agents[account].expirationBlock = expirationBlock;
        _agents[account].minable = minable;
        _agents[account].burnable = burnable;
        emit AgentGranted(account, credit, effectiveBlock, expirationBlock, minable, burnable, _msgSender());
    }

    /**
     * @dev Revoke the agent at the address
     * @param account Revoke agent address
     */
    function revokeAgent(address account) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        _revokeAgent(account);
    }

    function _revokeAgent(address account) internal {
        delete _agents[account];
        emit AgentRevoked(account, _msgSender());
    }

    /**
     * @dev Change the effective block number of the address agent
     */
    function changeEffectiveBlock(address account, uint256 effectiveBlock) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(effectiveBlock < _agents[account].expirationBlock, "AG012");
        _agents[account].effectiveBlock = effectiveBlock;
        emit AgentChangeEffectiveBlock(account, effectiveBlock, _msgSender());
    }

    /**
     * @dev Change the expiration block number of the address agent
     */
    function changeExpirationBlock(address account, uint256 expirationBlock) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(expirationBlock != _agents[account].expirationBlock && expirationBlock > block.number, "AG013");
        _agents[account].expirationBlock = expirationBlock;
        emit AgentChangeExpirationBlock(account, expirationBlock, _msgSender());
    }

    /**
     * @dev Change the minable status of the address agent
     */
    function switchMinable(address account, bool minable) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(minable != _agents[account].minable, "AG010");
        _agents[account].minable = minable;
        emit AgentSwitchMinable(account, minable, _msgSender());
    }

    /**
     * @dev Change the burnable status of the address agent
     */
    function switchBurnable(address account, bool burnable) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(burnable != _agents[account].burnable, "AG010");
        _agents[account].burnable = burnable;
        emit AgentSwitchBurnable(account, burnable, _msgSender());
    }

    /**
     * @dev Increase credit of the address agent
     * @dev After increase credit, the max credit and the remaining credit increase simultaneously
     */
    function increaseCredit(address account, uint256 credit) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(credit > 0, "AG007");
        _agents[account].maxCredit += credit;
        _agents[account].remainingCredit += credit;
        emit AgentIncreaseCredit(account, credit, _msgSender());
    }

    /**
     * @dev Decrease credit of the address agent
     * @dev After decrease credit, the max credit and the remaining credit decrease simultaneously
     */
    function decreaseCredit(address account, uint256 credit) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(credit > 0, "AG008");
        require(credit <= _agents[account].remainingCredit, "AG009");
        _agents[account].maxCredit -= credit;
        _agents[account].remainingCredit -= credit;
        emit AgentDecreaseCredit(account, credit, _msgSender());
    }

    function _increaseRemainingCredit(address account, uint256 amount) internal {
        if (getRemainingCredit(account) + amount > getMaxCredit(account)) {
            _agents[account].remainingCredit = getMaxCredit(account);
        } else {
            _agents[account].remainingCredit += amount;
        }
    }

    function _decreaseRemainingCredit(address account, uint256 amount) internal {
        _agents[account].remainingCredit -= amount;
    }

    // @dev This empty reserved space is put in place to allow future versions to add new
    // variables without shifting down storage in the inheritance chain.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[49] private __gap;
}