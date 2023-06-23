/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

//Fooyao Pass contract: 0x2d6c9ABB7cF4409063E3A6eaBBC428f3c1FF29f2
//webUI: https://fooyao.github.io/sign/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface interfaceMaster {
  function myadd_num(address theAddress) external view returns (uint256);
  function myadd_used(address target, address theAddress)  external view returns(uint256);

  function create_Proxies(address to, uint8 _n) external;
  function batch_mint(address to, address target, uint8 times, bytes calldata data) external payable;
  function batch_mints(address to, address target, uint8 times, bytes[] calldata data) external payable;
  function batch_withdrawal_1155(address to, address target, uint16 startWalletIndex, uint16 endWalletIndex, uint16 TokenId, uint16 amount) external;
  function batch_withdrawal_721(address to, address target, uint16 startWalletIndex, uint16 endWalletIndex, uint16 startID, uint16 amountPerTX) external;
  function batch_withdrawal_all_721(address to, address target, uint16 startID, uint16 amountPerTX) external;
  function batch_mint_withdrawal(address to, address target, address nftContract, uint8 times, int offset, bytes calldata data, uint16 amountPerTX) external payable;
}
contract Fooyao_batch_mint {
    address contractMaster = 0xEB97a1bAa3f4f875E29Cf082068498Bbd1177a3E;
    interfaceMaster fooyao = interfaceMaster(contractMaster);


    /**
    * @dev 获取你的地址数
    */
    function myadd_num(address theAddress) external view returns(uint256){
		return fooyao.myadd_num(theAddress);
	}

    /**
    * @dev 获取你该项目已使用地址数
    * @param target mint合约地址
    */
    function myadd_used(address target, address theAddress) external view returns(uint256){
		return fooyao.myadd_used(target, theAddress);
	}

    /**
    * @dev 创建地址
    * @param num 创建数量
    */
    function create_Proxies(uint8 num) external{
		fooyao.create_Proxies(msg.sender, num);
	}

    /**
    * @dev 批量mint，地址不足自动创建
    * @param target mint合约地址
    * @param times mint的次数
    * @param data mint的inputdata
    */
    function batch_mint(address target, uint8 times, bytes calldata data) external payable{
		fooyao.batch_mint{value: msg.value}(msg.sender, target, times, data);
	}

    /**
    * @dev 批量mint，地址不足自动创建
    * @param target mint合约地址
    * @param times mint的次数
    * @param data mint的inputdata数组
    */
  function batch_mints(address target, uint8 times, bytes[] calldata data) external payable{
		  fooyao.batch_mints{value: msg.value}(msg.sender, target, times, data);
	}

    /**
    * @dev 批量mint并提取，地址不足自动创建
    * @param target mint合约地址
    * @param nftContract NFT合约地址
    * @param times mint的次数
    * @param offset 与totalSupply偏移
    * @param data mint的inputdata
    */
    function batch_mint_withdrawal(address target, address nftContract, uint8 times, int offset, bytes calldata data, uint16 amountPerTX) external payable{
		fooyao.batch_mint_withdrawal{value: msg.value}(msg.sender, target, nftContract, times, offset, data, amountPerTX);
	}

    /**
    * @dev 批量提取ERC721
    * @param target NFT合约地址
    * @param startWalletIndex 钱包起始序号，0开始
    * @param endWalletIndex 钱包结束序号
    * @param startID NFT起始tokenID
    * @param amountPerTX 单个钱包mint数量
    */
    function batch_withdrawal_721(address target, uint16 startWalletIndex, uint16 endWalletIndex, uint16 startID, uint16 amountPerTX) external{
		fooyao.batch_withdrawal_721(msg.sender, target, startWalletIndex, endWalletIndex, startID, amountPerTX);
	}
    
    /**
    * @dev 批量提取ERC721，mint合约和NFT合约不同无法使用
    * @param target NFT合约地址
    * @param startID NFT起始tokenID
    * @param amountPerTX 单个钱包mint数量
    */
    function batch_withdrawal_all_721(address target, uint16 startID, uint16 amountPerTX) external{
		fooyao.batch_withdrawal_all_721(msg.sender, target, startID, amountPerTX);
	}
    
    /**
    * @dev 批量提取ERC721
    * @param target NFT合约地址
    * @param startWalletIndex 钱包起始序号，0开始
    * @param endWalletIndex 钱包结束序号
    * @param TokenId NFT的tokenID
    * @param amount 单个钱包NFT数量
    */
    function batch_withdrawal_1155(address target, uint16 startWalletIndex, uint16 endWalletIndex, uint16 TokenId, uint16 amount) external{
		fooyao.batch_withdrawal_1155(msg.sender, target, startWalletIndex, endWalletIndex, TokenId, amount);
	}
  

}