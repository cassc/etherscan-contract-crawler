// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface ITreasury {
    function bondCalculator(address _address) external view returns (address);

    function deposit(uint256 _amount, address _token, uint256 _profit) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function depositERC721(address _token, uint256 _tokenId) external;

    function withdrawERC721(address _token, uint256 _tokenId) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function allocatorManage(address _token, uint256 _amount) external;

    function claimNFTXRewards(address _liquidityStaking, uint256 _vaultId, address _rewardToken) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);
    
    function riskOffValuation(address _token) external view returns (uint256);

    function baseSupply() external view returns (uint256);
}