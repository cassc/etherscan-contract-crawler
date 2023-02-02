pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

//                           .,,,..                                                    
//                         .,,,,,,,,7                         .,,,.                    
//                        .,,.,,,,.,.                       I,,,,,,,I                  
//                        .,,,,,,,,.,.                      ,,.,,,.,.                  
//                        ?,,.,,,,.=IIIIIIIII.      7.IIIIII~..,,,,,,                  
//                         .,,..IIIIIIIIIIIIIII, 7.IIIIIIIIIIIII.,.,:                  
//                           .IIIIIIIIIIIIIIIIIII.?IIIIIIIIIIIIIII.                    
//                         7IIIIIIIIIIIIIIIIIIIIII.?IIIIIIIIIIIIIII,                   
//                         IIIIIIIIIIIIIIIIIIIIIIII.??IIIIIIIIIIIII.~.?                
//                        .IIIIII??=...,,,,,,,,,,,,..??IIIIIIIIIIIIIIIII?              
//                       .IIIII:,,,,,,,.,,,,,,,,,..,,????..,,,,,,,,..~??II             
//                     7IIIIII+,,,,,.,,,,,....,,,,,,,.,,,,,,.......,,,,,,,,.           
//                     IIIIII.,,,,,,,.~~.....=~77I+..,.?7~=....7.=.777II..,,7          
//                    .IIIIIIII:.....7~==...7?.7777777,I7.~=.?.7..777777777.           
//                   :IIIIIIIIIIIIIIIIIII.....=I77?..I.,,,..................           
//                   .IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII:........,IIIIIIIII7          
//                  7IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~           
//                  7?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?......IIIIIIIIIIIIII.            
//                  .?IIIIIIIIIIIIIIIIIIIIIIIIIIIII.,,:....::,.IIIIIIIIII.7            
//                  .?IIIIIIIIIIIIIIIIIIIIIIIIIIII.,::,....,::,.IIIIIIIII.             
//                  .??IIIIIIIIIIIIIIIIIIIIIIIIII.,::::,,,:::::,.IIIII??.              
//                  .???IIIIIIIIIIIIIIIIIIIIIIIIII,:::.,,,,::::,.IIIII?I               
//                  7???IIIIIIIIIIIIIIIIIIIIIIIIII,,::::::::::,.IIIIII?I               
//                   ????IIIIIIIIIIIIIIIIIIIIIIIIIII.,,:,,,,,.~IIIIIII?.               
//                   II????IIIIIIIIIIIIIIIIIIIIIIIIIIIIII?IIIIIIIIIII?I7               
//                    II????IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?I.                
//                     7.?????IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.                 
//                    7.??+.I???????IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~                  
//                   7.???????????~..........+IIIIIIIIIIIIIIIIIII?.7                   
//                  7:IIIIIIIIIII???????????????????????~......????I.                  
//                  .IIIIIIIIIIIIIIIIIIIIIIIIII?????????????????IIIII~                 
//                 .IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~                
//                 IIIIIIII?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.               
//                .IIIIIII?:?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII??IIIIIII7              
//               ,IIIIIII?.?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.?IIIIII.7             
//               .IIIIII??+?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII???IIIIII.7             
//    ___  ____   ________  ___  ____  ____   ____  ________  _______     ______   ________  
//   |_  ||_  _| |_   __  ||_  ||_  _||_  _| |_  _||_   __  ||_   __ \  .' ____ \ |_   __  | 
//     | |_/ /     | |_ \_|  | |_/ /    \ \   / /    | |_ \_|  | |__) | | (___ \_|  | |_ \_| 
//     |  __'.     |  _| _   |  __'.     \ \ / /     |  _| _   |  __ /   _.____`.   |  _| _  
//    _| |  \ \_  _| |__/ | _| |  \ \_    \ ' /     _| |__/ | _| |  \ \_| \____) | _| |__/ | 
//   |____||____||________||____||____|    \_/     |________||____| |___|\______.'|________|
//
//                                  https://kekverse.io/
//                               https://discord.gg/kekverse
//                  Created and drawn by Based Pleb - https://twitter.com/Based_Pleb
//                         Tech stuff by Mr F - https://twitter.com/MrFwashere
//                                Monthly Drops Contract

contract MonthlyDrops is ERC721A, DefaultOperatorFilterer {
    using Strings for uint;

    uint constant DROP_SIZE = 20;

    address public basedPleb;
    mapping(uint => string) public images;

    // eth distribution variables
    mapping(address => uint) public userClaimed;
    uint public claimedEthTotal;

    mapping(uint => uint) public claimedEth;
    uint ethPerShare = 0;
    uint[] dropEthPerShare;
    uint reservedEth = 0;

    constructor() ERC721A("MonthlyDrops", "MD")  {
        basedPleb = msg.sender;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function changePleb(address _pleb) external {
        require(msg.sender == basedPleb);
        basedPleb = _pleb;
    }

    function plebMint() external {
        require(msg.sender == basedPleb);
        newDrop();
        _mint(msg.sender, DROP_SIZE);
    }

    function setImage(uint _num, string memory _image) external {
        require(msg.sender == basedPleb);
        images[_num - 1] = _image;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Monthly Drops by Based Pleb #', tokenId.toString(), '",',
                '"description": "Special rewards for active Kekverse members",',
                '"image": "ipfs://', images[(tokenId-1) / DROP_SIZE] ,'"',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    // token id should start at 1, obviously

    function _startTokenId() internal pure override returns (uint) {
        return 1;
    }

    // eth distribution functions

    function unwrap(address weth) external {
        uint bal = WETH(weth).balanceOf(address(this));
        WETH(weth).withdraw(bal);
    }

    function undistributedEth() public view returns (uint) {
        return address(this).balance - reservedEth;
    }

    function distribute() internal {
        uint undistributed = undistributedEth();
        uint undistributedPerShare = undistributed / totalSupply();
        reservedEth += undistributedPerShare * totalSupply();
        ethPerShare += undistributedPerShare;
    }

    function newDrop() internal {
        if (totalSupply() > 0) {
            distribute();
        }
        dropEthPerShare.push(ethPerShare);
    }

    function withdrawEth(uint32[] calldata ids) public {
        distribute();
        uint totalClaim = 0;

        for (uint i = 0; i < ids.length; i++) {
            uint id = ids[i];

            require(ownerOf(id) == msg.sender, "Must own the token");

            uint drop = (id-1) / DROP_SIZE;
            uint rewardsForToken = ethPerShare - claimedEth[id] - dropEthPerShare[drop];

            claimedEth[id] += rewardsForToken;
            totalClaim += rewardsForToken;
        }

        (bool success,) = address(msg.sender).call{value: totalClaim}('');
        require(success);
        reservedEth -= totalClaim;
        userClaimed[msg.sender] += totalClaim;
        claimedEthTotal += totalClaim;
    }

    function checkEth(uint32[] calldata ids) public view returns (uint) {
        uint totalClaim = 0;
        uint undistributed = undistributedEth();
        uint tempEthPerShare = ethPerShare + undistributed / totalSupply();

        for (uint i = 0; i < ids.length; i++) {
            uint id = ids[i];
            uint drop = (id-1) / DROP_SIZE;
            uint rewardsForToken = tempEthPerShare - claimedEth[id] - dropEthPerShare[drop];
            totalClaim += rewardsForToken;
        }

        return totalClaim;
    }

    // opensea garbage

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) public payable override onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // for UI

    function batchOwners(uint startFrom, uint length) public view returns (address[] memory) {
        address[] memory addrs = new address[](length);
        uint writeIndex = 0;
        for (uint readIndex = startFrom; writeIndex < length; readIndex++) {
            addrs[writeIndex] = ownerOf(readIndex);
            writeIndex++;
        }
        return addrs;
    }
}

interface WETH {
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
}