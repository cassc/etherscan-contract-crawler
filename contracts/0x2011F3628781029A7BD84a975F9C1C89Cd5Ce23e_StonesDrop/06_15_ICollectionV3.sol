// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity 0.8.12;

interface ICollectionV3 {
    function initialize(
        string memory uri,
        uint256 _total,
        uint256 _whitelistedStartTime,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amount,
        uint256 _percent,
        address _admin,
        address _facAddress
    ) external;

    function __CollectionV3_init_unchained(
        string memory uri,
        uint256 _total,
        uint256 _whitelistedStartTime,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amount,
        uint256 _percent,
        address _admin,
        address _facAddress
    ) external;

    function addExternalAddresses(
        address _token,
        address _stone,
        address _treasure
    ) external;

    function recoverToken(address _token) external;

    function changeOnlyWhitelisted(bool _status) external;

    function buy(address buyer, uint256 _id) external;

    function mint(address to, uint256 _id) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amount_
    ) external;

    function addPayees(address[] memory payees_, uint256[] memory sharePerc_)
        external;

    function _addPayee(address account, uint256 sharePerc_) external;

    function release() external;

    function getAmountPer(uint256 sharePerc) external view returns (uint256);

    function calcPerc(uint256 _amount, uint256 _percent)
        external
        pure
        returns (uint256);

    function calcTrasAndShare() external view returns (uint256, uint256);

    function setStarTime(uint256 _starTime) external;

    function setEndTime(uint256 _endTime) external;

    function setWhiteListUser(address _addr) external;

    function setBatchWhiteListUser(address[] calldata _addr) external;

    function setAmount(uint256 _amount) external;

    function delShare(address account) external;

    function totalReleased() external view returns (uint256);

    function released(address account) external view returns (uint256);

    function shares(address account) external view returns (uint256);

    function allShares() external view returns (address[] memory);

    function available() external view returns (uint256);
}