pragma solidity 0.8.4;

interface IConfig {
    
    event AdminFeeUpdated(uint16 newAdminFee);

    
    event MaxBorrowDurationUpdated(uint256 newMaxBorrowDuration);

    
    event MinBorrowDurationUpdated(uint256 newMinBorrowDuration);

    
    event ERC20Permit(address indexed erc20Contract, bool isPermitted);

    
    event ERC721Permit(address indexed erc721Contract, bool isPermitted);

    
    event AdminFeeReceiverUpdated(address);

    
    function maxBorrowDuration() external view returns (uint256);

    
    function minBorrowDuration() external view returns (uint256);

    
    function adminShare() external view returns (uint16);

    
    function updateMaxBorrowDuration(uint256 _newMaxBorrowDuration)
        external;

    
    function updateMinBorrowDuration(uint256 _newMinBorrowDuration)
        external;

    
    function updateAdminShare(uint16 _newAdminShare) external;

    
    function updateAdminFeeReceiver(address _newAdminFeeReceiver) external;

    
    function getERC20Permit(address _erc20) external view returns (bool);

    
    function getERC721Permit(address _erc721) external view returns (bool);

    
    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits)
        external;

    
    function setERC721Permits(address[] memory _erc721s, bool[] memory _permits)
        external;
}