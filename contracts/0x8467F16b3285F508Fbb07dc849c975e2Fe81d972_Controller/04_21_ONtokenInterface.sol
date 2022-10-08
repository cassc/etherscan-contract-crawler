// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ONtokenInterface {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnONtoken(address account, uint256 amount) external;

    function reduceCollaterization(
        uint256[] calldata collateralsAmountsForReduce,
        uint256[] calldata collateralsValuesForReduce,
        uint256 onTokenAmountBurnt
    ) external;

    function getCollateralAssets() external view returns (address[] memory);

    function getCollateralsAmounts() external view returns (uint256[] memory);

    function getCollateralConstraints() external view returns (uint256[] memory);

    function collateralsValues(uint256) external view returns (uint256);

    function getCollateralsValues() external view returns (uint256[] memory);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function collaterizedTotalAmount() external view returns (uint256);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function expiryTimestamp() external view returns (uint256);

    function getONtokenDetails()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        );

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external;

    function isPut() external view returns (bool);

    function mintONtoken(
        address account,
        uint256 amount,
        uint256[] memory collateralsAmountsForMint,
        uint256[] memory collateralsValuesForMint
    ) external;

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function strikeAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function underlyingAsset() external view returns (address);
}