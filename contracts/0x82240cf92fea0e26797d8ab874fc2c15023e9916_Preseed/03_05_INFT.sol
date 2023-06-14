pragma solidity 0.8.19;

interface INFT {
    enum Rarity { Common, Rare, Legendary, Epic }
    function claim(address _receiver, Rarity _rarity, uint256 _value) external;
}