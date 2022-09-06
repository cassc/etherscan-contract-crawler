// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;
interface INibblVaultFactory {
    event Fractionalise(address assetAddress, uint256 assetTokenID, address proxyVault);
    event BasketCreated(address indexed _curator, address indexed _basket);

    function createVault(address _assetAddress, address _curator, string memory _name, string memory _symbol, uint256 _assetTokenID, uint256 _initialSupply, uint256 _initialTokenPrice, uint256 _minBuyoutTime) external payable returns(address payable _proxyVault);
    function withdrawAdminFee() external;
    function proposeNewAdminFeeAddress(address _newFeeAddress) external;
    function updateNewAdminFeeAddress() external;
    function proposeNewAdminFee(uint256 _newFee) external;
    function updateNewAdminFee() external;
    function proposeNewVaultImplementation(address _newVaultImplementation) external;
    function updateVaultImplementation() external;
    function pause() external;
    function unPause() external;
    function createBasket(address _curator, string memory _mix) external returns(address);
    function getBasketAddress(address _curator, string memory _mix) external view returns(address);
    function proposeNewBasketImplementation(address _newBasketImplementation) external;
    function updateBasketImplementation() external;

}