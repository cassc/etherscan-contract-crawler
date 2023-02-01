// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./interfaces/IAdapterEth.sol";

contract HedgepieAdapterManagerEth is Ownable {
    struct AdapterInfo {
        address addr;
        string name;
        address stakingToken;
        bool status;
    }

    // Info of each adapter
    AdapterInfo[] public adapterInfo;
    // investor address
    address public investor;

    event AdapterAdded(address strategy);
    event AdapterRemoveed(address strategy);
    event InvestorUpdated(address investor);

    /**
     * @notice Throws if adapter is not active
     */
    modifier onlyActiveAdapter(address _adapter) {
        bool isExisted = false;
        for (uint256 i = 0; i < adapterInfo.length; i++) {
            if (
                adapterInfo[i].addr == address(_adapter) &&
                adapterInfo[i].status
            ) {
                isExisted = true;
                break;
            }
        }
        require(isExisted, "Error: Adapter is not active");
        _;
    }

    /**
     * @notice Throws if called by any account other than the investor.
     */
    modifier onlyInvestor() {
        require(msg.sender == investor, "Error: caller is not investor");
        _;
    }

    /**
     * @notice Get a list of adapters
     */
    function getAdapters() external view returns (AdapterInfo[] memory) {
        return adapterInfo;
    }

    /**
     * @notice Get strategy address of adapter contract
     * @param _adapter  adapter address
     */
    function getAdapterStrat(address _adapter)
        external
        view
        onlyActiveAdapter(_adapter)
        returns (address adapterStrat)
    {
        adapterStrat = IAdapterEth(_adapter).strategy();
    }

    // ===== Owner functions =====
    /**
     * @notice Add adapter
     * @param _adapter  adapter address
     */
    /// #if_succeeds {:msg "Adapter not set correctly"} adapterInfo.length == old(adapterInfo.length) + 1;
    function addAdapter(address _adapter) external onlyOwner {
        require(_adapter != address(0), "Invalid adapter address");

        adapterInfo.push(
            AdapterInfo({
                addr: _adapter,
                name: IAdapterEth(_adapter).name(),
                stakingToken: IAdapterEth(_adapter).stakingToken(),
                status: true
            })
        );

        emit AdapterAdded(_adapter);
    }

    /**
     * @notice Remove adapter
     * @param _adapterId  adapter id
     * @param _status  adapter status
     */
    /// #if_succeeds {:msg "Status not updated"} adapterInfo[_adapterId].status == _status;
    function setAdapter(uint256 _adapterId, bool _status) external onlyOwner {
        require(_adapterId < adapterInfo.length, "Invalid adapter address");

        adapterInfo[_adapterId].status = _status;
    }

    /**
     * @notice Set investor contract
     * @param _investor  investor address
     */
    /// #if_succeeds {:msg "Investor not set correctly"} investor == _investor;
    function setInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        investor = _investor;
        emit InvestorUpdated(investor);
    }
}