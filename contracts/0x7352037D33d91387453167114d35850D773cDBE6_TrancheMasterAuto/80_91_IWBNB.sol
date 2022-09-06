//SPDX-License-Identifier: MIT

pragma solidity >=0.4.18 <=0.6.12;

interface IWBNB {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

//WBNB contract address:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c

// abstract contract WBNBCaller {
//     WBNB public wbnb;
//     constructor (address _contractAddress)  {
//         wbnb = WBNB( _contractAddress );
//     }

//     function getTotalSupply() public view returns(uint) {
//         return wbnb.totalSupply();
//     }
//     function deposit() public  {
//         wbnb.deposit();
//     }

// }