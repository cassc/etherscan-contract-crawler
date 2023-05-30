// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OBOControl is Ownable {
    address public oboAdmin;
    uint256 public constant newAddressWaitPeriod = 1 days;
    bool public canAddOBOImmediately = true;

    // List of approved on behalf of users.
    mapping(address => uint256) public approvedOBOs;

    event NewOBOAddressEvent(address OBOAddress, bool action);

    event NewOBOAdminAddressEvent(address oboAdminAddress);

    modifier onlyOBOAdmin() {
        require(
            owner() == _msgSender() || oboAdmin == _msgSender(),
            "not oboAdmin"
        );
        _;
    }

    function setOBOAdmin(address _oboAdmin) external onlyOwner {
        oboAdmin = _oboAdmin;
        emit NewOBOAdminAddressEvent(_oboAdmin);
    }

    /**
     * Add a new approvedOBO address. The address can be used after wait period.
     */
    function addApprovedOBO(address _oboAddress) external onlyOBOAdmin {
        require(_oboAddress != address(0), "cant set to 0x");
        require(approvedOBOs[_oboAddress] == 0, "already added");
        approvedOBOs[_oboAddress] = block.timestamp;
        emit NewOBOAddressEvent(_oboAddress, true);
    }

    /**
     * Removes an approvedOBO immediately.
     */
    function removeApprovedOBO(address _oboAddress) external onlyOBOAdmin {
        delete approvedOBOs[_oboAddress];
        emit NewOBOAddressEvent(_oboAddress, false);
    }

    /*
     * Add OBOAddress for immediate use. This is an internal only Fn that is called
     * only when the contract is deployed.
     */
    function addApprovedOBOImmediately(address _oboAddress) internal {
        require(_oboAddress != address(0), "addr(0)");
        // set the date to one in past so that address is active immediately.
        approvedOBOs[_oboAddress] = block.timestamp - newAddressWaitPeriod - 1;
        emit NewOBOAddressEvent(_oboAddress, true);
    }

    function addApprovedOBOAfterDeploy(address _oboAddress)
        external
        onlyOBOAdmin
    {
        require(canAddOBOImmediately == true, "disabled");
        addApprovedOBOImmediately(_oboAddress);
    }

    function blockImmediateOBO() external onlyOBOAdmin {
        canAddOBOImmediately = false;
    }

    /*
     * Helper function to verify is a given address is a valid approvedOBO address.
     */
    function isValidApprovedOBO(address _oboAddress)
        public
        view
        returns (bool)
    {
        uint256 createdAt = approvedOBOs[_oboAddress];
        if (createdAt == 0) {
            return false;
        }
        return block.timestamp - createdAt > newAddressWaitPeriod;
    }

    /**
     * @dev Modifier to make the obo calls only callable by approved addressess
     */
    modifier isApprovedOBO() {
        require(isValidApprovedOBO(msg.sender), "unauthorized OBO user");
        _;
    }
}