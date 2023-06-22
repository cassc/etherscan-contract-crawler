/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
// Just for Neverland.
//This contract is free to use before 2024/6/1,After that,the holders of robot or bigplayer are free to use it.
//本合约在2024年6月1日前对所有人完全免费，之后robot或者bigplayer NFT持有者仍可免费使用。
//Feel free to send eth as tip to this contract.(如需打赏，可直接发送eth到此合约)
//Before using this contract,u have to understand how to use hexadecimal data to interact with other contracts.Otherwise don't use it.
//在使用本合约前，你需要掌握如何用十六进制数据与其他合约交互,否则不要使用。

pragma solidity ^0.8.18;

interface IERC721{
    function transferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Neverland{

    address Neverlander;
    address private immutable original;
    mapping(address => uint256) private salt_nonce;
    mapping(address =>address[]) private owned_contract;
    mapping(address => bool) public approved;
    bool public approvedactive;
    IERC721 robot=IERC721(0x81Ca1F6608747285c9c001ba4f5ff6ff2b5f36F8);
    IERC721 bigplayer;

    constructor() payable {
        original = address(this);
        Neverlander = tx.origin;
    }

    modifier onlyowner(){
        require(msg.sender==Neverlander);
        _;
    }

    modifier onlyapproved(){
        if (approvedactive==true){
            require(approved[msg.sender] ||robot.balanceOf(msg.sender)>0 ||bigplayer.balanceOf(msg.sender)>0 );
        }
        _;
    }
    modifier onlyoriginal(){
        require(msg.sender==original);
        _;
    }
    //create smart contract wallet to use.total is the amount of smart contract wallets u want to create.
    //创建你的智能合约钱包。total是你想创建智能合约钱包的数量。
    function create_proxy(uint256 total) public onlyapproved{ 
        for (uint i; i < total;++i) {
            salt_nonce[msg.sender]+=1;
            bytes memory bytecode = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
            bytes32 salt = keccak256(abi.encodePacked(salt_nonce[msg.sender],msg.sender));
 			assembly {
	            let proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
                }
            bytes32 hashed_bytecode = keccak256(abi.encodePacked(bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3))));
            address proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                hashed_bytecode
                )))));          
            owned_contract[msg.sender].push(address(proxy));
        
        }
    }
    //call your smart contract wallet.
    //调用你的智能合约钱包。
    //if u had created 100 wallets,begin=1,end=10 means u call the wallets from wallet[1] to wallet[10].(如果你创建了100个钱包，begin=1 end=10意味着你要调用钱包1到钱包10。)

    //destination means the contract u want to interact with your smart contract wallets. (destination意味着你想用合约钱包交互的目标合约。)

    //data means u want to send this hexadecimal data to destination with your smart contract wallets.(data意味着你想用合约钱包给目标合约发送这样的十六进制数据)

    //value means u want to send data with this amount of eth per wallet,and the unit of value is wei,1eth=1e18 wei,
    //it means if u want to send 0.01 eth per wallet and u want to call 10 wallets,the value is 0.01*1000000000000000000 and u have to pay 0.1eth with this method to this contract.or it will fail.

    //value意味着你每个合约钱包发送十六进制数据时同时附带这么多的wei,1eth=10的十八次方 wei,如果你想用十个合约钱包给目标合约发送0.01eth,那么value就要填0.01*1000000000000000000并且调用此方法时支付0.1eth,否则调用会失败。
    function call_proxy(uint256 begin,uint256 end,address destination,bytes memory data,uint256 value) public payable onlyapproved {
        require(end<=owned_contract[msg.sender].length);
        uint256 i=begin;
        bytes memory encoded_data=abi.encodeWithSignature("external_call(address,bytes,uint256)", destination,data,value);
        if (value>0){
            require(msg.value>=(end-begin+1)*value);
        }
        for (i; i <= end; ++i) {
            address proxy_address=owned_contract[msg.sender][i-1];
            assembly {
                let succeeded := call(
                    gas(),
                    proxy_address,
                    value,
                    add(encoded_data, 0x20),
                    mload(encoded_data),
                    0,
                    0
                )
            }
			}
        }
    //call your smart contract wallet to mint nft and transfer to your address.This method is almost the same as call_proxy but if u mint nft,u have to use this method.
    //调用你的智能合约钱包铸造NFT并自动归集到主钱包。 此方法的参数基本相当于call_proxy,但是如果你需要mint nft并归集，那么你要用此方法。
    function call_proxy_NFT(uint256 begin,uint256 end,address destination,bytes memory data,uint256 value) public payable onlyapproved {
        require(end<=owned_contract[msg.sender].length);
        uint256 i=begin;
        bytes memory encoded_data=abi.encodeWithSignature("external_call(address,bytes,uint256)", destination,data,value);
        if (value>0){
            require(msg.value>=(end-begin+1)*value);
        }
        for (i; i <= end; ++i) {
            address proxy_address=owned_contract[msg.sender][i-1]; 
            assembly {
                let succeeded := call(
                    gas(),
                    proxy_address,
                    value,
                    add(encoded_data, 0x20),
                    mload(encoded_data),
                    0,
                    0
                )
            }
            IERC721 nft=IERC721(destination);
            require(nft.balanceOf(proxy_address)==1);
            uint256 tokenid=nft.totalSupply();
            bytes memory transfer_data=abi.encodeWithSignature("transferFrom(address,address,uint256)", proxy_address,msg.sender,tokenid);
            bytes memory call_data=abi.encodeWithSignature("external_call(address,bytes,uint256)", destination,transfer_data,0);
            assembly {
                let succeeded := call(
                    gas(),
                    proxy_address,
                    0,
                    add(call_data, 0x20),
                    mload(call_data),
                    0,
                    0
                )
            }  
            require(nft.balanceOf(proxy_address)==0);          
			}
        }
    //below these methods is nothing to do with u ,just ignore them.
    //以下这些方法几乎与你无关，请忽略。
    function external_call(address destination,bytes memory data,uint256 value) external payable onlyoriginal{
        (bool success, )=destination.call{value:value}(data);
        require(success==true);
    }
    function withdrawETH() public{
        payable(Neverlander).transfer(address(this).balance);
    }
    function setapprovedactive(bool set)public onlyowner{
        approvedactive=set;
    }
    function setbigplayer(address bigplayerpass) public onlyowner{
        bigplayer=IERC721(bigplayerpass);
    }
    function setapproved(address[] calldata approved_addr,bool set) public onlyowner{
        for (uint8 i;i<approved_addr.length;i++){
            approved[approved_addr[i]]=set;
        }
    }
    //After 2024/6/1,if not a holder of robot or bigplayer,you can spend 0.1eth to become vip to use this contract forever.
    //在2024/6/1之后，如果不想成为robot与bigplayer NFT持有者，花费0.1eth也可永久免费使用。
    function becomevip() public payable{
        require(msg.value>=0.1 ether);
        approved[msg.sender]=true;
    }
    function onERC721Received (
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4 result){
        result = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    fallback() external payable{}



}