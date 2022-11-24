// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MediaEyeMerkleDistributor {
    using Counters for Counters.Counter;
    Counters.Counter private _airdropIds;

    struct Airdrop {
        address owner;
        bytes32 merkleRoot;
        bool cancelable;
        uint256 tokenAmount;
        mapping(address => bool) collected;
    }

    IERC20 tokenContract;

    event StartAirdrop(uint256 airdropId);
    event AirdropTransfer(uint256 id, address addr, uint256 num);

    mapping(uint256 => Airdrop) public airdrops;

    constructor(IERC20 _tokenContract) {
        tokenContract = _tokenContract;
    }

    function startAirdrop(
        bytes32 _merkleRoot,
        bool _cancelable,
        uint256 _tokenAmount
    ) public {
        _airdropIds.increment();
        Airdrop storage newAirdrop = airdrops[_airdropIds.current()];
        newAirdrop.owner = msg.sender;
        newAirdrop.merkleRoot = _merkleRoot;
        newAirdrop.cancelable = _cancelable;
        newAirdrop.tokenAmount = _tokenAmount;

        tokenContract.transferFrom(msg.sender, address(this), _tokenAmount);
        emit StartAirdrop(_airdropIds.current());
    }

    function setRoot(uint256 _id, bytes32 _merkleRoot) public {
        require(
            msg.sender == airdrops[_id].owner,
            "Only owner of an airdrop can set root"
        );
        airdrops[_id].merkleRoot = _merkleRoot;
    }

    function collected(uint256 _id, address _who) public view returns (bool) {
      return airdrops[_id].collected[_who];
    }

    function nextAirdropId() public view returns (uint256) {
      return _airdropIds.current() + 1;
    }

    function contractTokenBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function contractTokenBalanceById(uint256 _id)
        public
        view
        returns (uint256)
    {
        return airdrops[_id].tokenAmount;
    }

    function endAirdrop(uint256 _id) public returns (bool) {
        require(airdrops[_id].cancelable, "this presale is not cancelable");
        // only owner
        require(
            msg.sender == airdrops[_id].owner,
            "Only owner of an airdrop can end the airdrop"
        );
        require(airdrops[_id].tokenAmount > 0, "Airdrop has no balance left");
        // require(airdrops[_id].startTime <= block.timestamp - 43800 minutes, "Must wait 1 month before ending airdrop"); // 1 month
        uint256 transferAmount = airdrops[_id].tokenAmount;
        airdrops[_id].tokenAmount = 0;
        require(
            tokenContract.transferFrom(
                address(this),
                airdrops[_id].owner,
                transferAmount
            ),
            "Unable to transfer remaining balance"
        );
        return true;
    }

    function getTokens(
        uint256 _id,
        bytes32[] memory _proof,
        address _who,
        uint256 _amount
    ) public returns (bool success) {
        Airdrop storage airdrop = airdrops[_id];

        require(
            airdrop.collected[_who] != true,
            "User has already collected from this airdrop"
        );
        require(_amount > 0, "User must collect an amount greater than 0");
        require(
            airdrop.tokenAmount >= _amount,
            "The airdrop does not have enough balance for this withdrawal"
        );
        require(
            msg.sender == _who,
            "Only the recipient can receive for themselves"
        );

        if (
            !checkProof(_id, _proof, leafFromAddressAndNumTokens(_who, _amount))
        ) {
            // throw if proof check fails, no need to spend gas
            require(false, "Invalid proof");
            // return false;
        }

        airdrop.tokenAmount = airdrop.tokenAmount - _amount;
        airdrop.collected[_who] = true;

        if (tokenContract.transferFrom(address(this), _who, _amount) == true) {
            emit AirdropTransfer(_id, _who, _amount);
            return true;
        }
        // throw if transfer fails, no need to spend gas
        require(false);
    }

    function addressToAsciiString(address x)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        uint256 x_int = uint256(uint160(address(x)));

        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(x_int / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uintToStr(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (i != 0) {
            bstr[(k--) - 1] = bytes1(uint8(48 + (i % 10)));
            i /= 10;
        }
        return string(bstr);
    }

    function leafFromAddressAndNumTokens(address _account, uint256 _amount)
        internal
        pure
        returns (bytes32)
    {
        string memory prefix = "0x";
        string memory space = " ";

        bytes memory leaf = abi.encodePacked(
            prefix,
            addressToAsciiString(_account),
            space,
            uintToStr(_amount)
        );

        return bytes32(sha256(leaf));
    }

    function checkProof(
        uint256 _id,
        bytes32[] memory _proof,
        bytes32 hash
    ) internal view returns (bool) {
        bytes32 el;
        bytes32 h = hash;

        for (
            uint256 i = 0;
            _proof.length != 0 && i <= _proof.length - 1;
            i += 1
        ) {
            el = _proof[i];

            if (h < el) {
                h = sha256(abi.encodePacked(h, el));
            } else {
                h = sha256(abi.encodePacked(el, h));
            }
        }

        return h == airdrops[_id].merkleRoot;
    }
}