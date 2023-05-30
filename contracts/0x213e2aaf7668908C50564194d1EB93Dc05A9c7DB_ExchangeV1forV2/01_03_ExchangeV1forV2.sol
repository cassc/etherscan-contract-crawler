//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

//ERC20規格を読み込むための準備
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract  ExchangeV1forV2 is Ownable {

    IERC20 public jpyc_v1; // インターフェース
    IERC20 public jpyc_v2; // インターフェース
	uint8 public incentive; // インセンティブ率
	uint8 constant inecentive_max = 20; // 最大インセンティブ率

    // _incentiveは百分率で表示
	constructor(address _jpyc_v1, address _jpyc_v2, uint8 _incentive) {
		jpyc_v1 = IERC20(_jpyc_v1);
		jpyc_v2 = IERC20(_jpyc_v2);
		setIncentive(_incentive);
	}

    // JPYCv1と交換
	function swap() external {
		uint256 jpyc_v1_amount = jpyc_v1.balanceOf(msg.sender);
		uint256 jpyc_v2_amount = jpyc_v1_amount * (100 + incentive) / 100;
		jpyc_v1.transferFrom(msg.sender, owner(), jpyc_v1_amount);
		jpyc_v2.transferFrom(owner(), msg.sender, jpyc_v2_amount);
	}

	// インセンティブの設定
	function setIncentive(uint8 _incentive) onlyOwner public {
		require(_incentive <= inecentive_max, "_incentive is greater than max incentive");
		incentive = _incentive;
	}

    // ERC20を引き出す
	// JPYCv1とJPYCv2はこのコントラクトでは所有しないが念の為
	function withdrawERC20(address _tokenAddress, address to) onlyOwner external {
		uint256 ERC20_amount = IERC20(_tokenAddress).balanceOf(address(this));
		IERC20(_tokenAddress).transfer(to, ERC20_amount);
	}
}