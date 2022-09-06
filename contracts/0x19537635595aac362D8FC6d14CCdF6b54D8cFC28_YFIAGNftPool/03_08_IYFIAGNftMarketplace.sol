// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IYFIAGNftMarketplace {
    // Event =================================================================================
    event PriceChanged(uint256 _tokenId, uint256 _price, address _tokenAddress, address _user);
    event RoyaltyChanged(uint256 _tokenId, uint256 _royalty, address _user);
    event FundsTransfer(uint256 _tokenId, uint256 _amount, address _user);

    //Function ================================================================================

    function withdraw() external;

    function withdraw(address _user, uint256 _amount) external;

    function withdraw(address _tokenErc20, address _user) external;

    function setPlatformFee(uint256 _newFee) external;

    function getBalance() external view returns(uint256);

    function mint(address _to,address _token, string memory _uri, uint256 _royalty, bool _isRoot) external;

    function mintFragment(address _to,uint256 _rootTokenId) external;

    function setPriceAndSell(uint256 _tokenId, uint256 _price) external;

    function buy(uint256 _tokenId) external payable;

    function isForSale(uint256 _tokenId) external view returns(bool);

    function getAmountEarn(address _user, address _tokenAddress) external view returns(uint256);

    function isOwnerOfRoot(uint256 _tokenId,address owner) external view returns(bool);

    function setDefaultAmountEarn(address _user, address _tokenAddress) external;

    function setPlatformFeeAddress(address newPlatformFeeAddess) external;

    function burnByLaunchpad(address account,uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    function getMaxFragment() external view returns(uint256);
}