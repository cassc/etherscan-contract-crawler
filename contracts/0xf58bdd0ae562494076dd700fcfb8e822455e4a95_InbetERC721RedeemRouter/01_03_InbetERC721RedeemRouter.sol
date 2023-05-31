// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721Burnable {
    function ownerOf(uint tokenId) external view returns(address);
    function burn(uint tokenId) external;
}

interface IDGinBetweeners {
    function mint(address to, uint tokenId) external;
}

contract InbetERC721RedeemRouter is Ownable {

    IERC721Burnable public token;
    IDGinBetweeners public mirrorToken;

    event TokenRedeemed(address indexed account, uint[] tokenIds, bytes metadata);

    uint public startTime = 0;
    uint public endTime = 0;

    // uint public price = 0.0055 ether;
    uint public price = 0 ether;

    mapping(uint => bool) public redeemed;

    address payable public moneyReceiver = payable(0xDC9781Bf813d46B686e8458d81457C184722C212);
    address payable public feeReceiver = payable(0xAc4B36C464D12A8B6eFD2410d36aC2928c07038C);

    address public verifyAddress;
    mapping(bytes => bool) public usedSig;

    event ErrorMoneySend(address indexed to, uint amount);

    constructor(IERC721Burnable _token, IDGinBetweeners _mirrorToken, address _verifyAddress) {
        token = _token;
        verifyAddress = _verifyAddress;
        mirrorToken = _mirrorToken;
    }

    function update(uint _startTime, uint _endTime, uint _price) public onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        price = _price;
    }

    function redeemBatch(uint[] memory /*tokenIds*/, bytes memory /*metadata*/) external payable {
        revert("inactive");
    }
    
    function redeemBatchWithVerification(uint[] memory tokenIds, bytes memory metadata, uint _amount, uint _seed, bytes memory signature) external payable {
        require(startTime < block.timestamp && block.timestamp < endTime, "burn inactive");
//        require(tokenIds.length == 1, "invalid tokenIds");
        require(!usedSig[signature], "seed already used");

        require(verify(msg.sender, _amount, _seed, signature), "invalid signature");
        usedSig[signature] = true;

        require(msg.value == price * tokenIds.length + _amount, "invalid value");

        (bool success, ) = moneyReceiver.call{value: price * tokenIds.length}("");
        if(!success) {
            emit ErrorMoneySend(moneyReceiver, price * tokenIds.length);
        }

        (success, ) = feeReceiver.call{value: _amount}("");
        if(!success){
            emit ErrorMoneySend(moneyReceiver, _amount);
        }

        for(uint i = 0; i < tokenIds.length; i++) {
            require(!redeemed[tokenIds[i]], "token already redeemed");
            token.burn(tokenIds[i]);
            redeemed[tokenIds[i]] = true;
            mirrorToken.mint(msg.sender, tokenIds[i]);
        }

        emit TokenRedeemed(msg.sender, tokenIds, metadata);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = moneyReceiver.call{value: address(this).balance}("");
        if(!success) {
            emit ErrorMoneySend(msg.sender, address(this).balance);
        }
    }

    /// signature methods.
    function verify(
        address _userAddress,
        uint _amount,
        uint _seed,
        bytes memory signature
    )
    public view returns(bool)
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(_userAddress, _amount, _seed, address(this))));
        return (recoverSigner(message, signature) == verifyAddress);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig, (uint8, bytes32, bytes32));

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}