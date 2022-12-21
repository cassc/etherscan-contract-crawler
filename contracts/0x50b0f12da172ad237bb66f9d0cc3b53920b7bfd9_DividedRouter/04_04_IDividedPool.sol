// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)

interface IDividedPool {
    function collection() external returns (address);
    function LP_PER_NFT() external returns (uint256);
    function swap(uint256[] calldata tokensOut, address from, address to) external returns (int128);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}