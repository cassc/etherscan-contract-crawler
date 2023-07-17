// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.20;

import {Program, Params} from "./Program.sol";
import {ERC721} from "../lib/solmate/src/tokens/ERC721.sol";
import {Antigraviton} from "./Antigraviton.sol";
import {Research} from "./Research.sol";
import {LibString} from "../lib/solady/src/utils/LibString.sol";
import {ERC2981} from "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract AngelMatter is ERC721("Angel Matter", "AM"), ERC2981 {
    uint256 constant SUPPLY = 3333;
    uint256 constant PRICE = 0.01618 ether;
    uint256 constant COLLISION = 3333333 ether;

    Antigraviton public anti;
    Research public research;
    Program public program;

    address public owner;
    uint256 public startTime;

    uint256 public currentId;

    mapping(uint256 => uint256) public prestige;
    mapping(uint256 => uint256) public seed;
    mapping(uint256 => uint8) public level;
    mapping(uint256 => uint8) public spin;
    mapping(uint256 => uint8) public redacted;
    mapping(uint256 => string) public prism;

    mapping(uint256 => uint256) public claimed;

    modifier onlyHolder(uint256 id) {
        require(msg.sender == ownerOf(id));
        _;
    }

    constructor(address _owner, uint256 _startTime) {
        anti = new Antigraviton();
        research = new Research();
        program = new Program();

        owner = _owner;
        startTime = _startTime;

        _setDefaultRoyalty(_owner, 333);
    }

    function mint(uint256 _amount) external payable {
        require(startTime <= block.timestamp || msg.sender == owner);
        require(msg.value == _amount * PRICE || msg.sender == owner);
        require(currentId + _amount <= SUPPLY);
        uint256 i;
        for (i; i < _amount; ) {
            unchecked {
                uint256 id = ++currentId;
                seed[id] = _prandom(id);
                _mint(msg.sender, id);
                ++i;
                if (id % 2 == 0) {
                    spin[id] = 1;
                }
                prism[id] = "0";
            }
        }
    }

    function claimAnti(uint256 id) public onlyHolder(id) {
        uint256 vb = virtualAnti(id);
        claimed[id] += vb;
        anti.mint(msg.sender, vb);
    }

    function virtualAnti(uint256 id) public view returns (uint256) {
        return ((block.timestamp - startTime) * 1 ether) - claimed[id];
    }

    function collide(uint256 id, string memory signal) external onlyHolder(id) {
        require((anti.balanceOf(msg.sender) + virtualAnti(id)) >= COLLISION);

        claimAnti(id);
        anti.burn(msg.sender, COLLISION);
        research.mint(msg.sender, ++prestige[id]);
        if (redacted[id] == 1) {
            redacted[id] = 0;
            research.mint(msg.sender, 0);
        }

        seed[id] = uint256(keccak256(abi.encodePacked(signal, id)));
        level[id] = 0;
        prism[id] = "0";
    }

    function observe(
        uint256 id,
        uint256[][] memory arr
    ) external onlyHolder(id) {
        require(arr.length == 5);
        string memory str = "[";
        for (uint256 i; i < 5; ++i) {
            require(arr[i].length == 5);
            str = string.concat(str, "[");
            for (uint256 j; j < 5; ++j) {
                require(arr[i][j] < 6);
                str = string.concat(str, LibString.toString(arr[i][j]));
                if (j < 4) {
                    str = string.concat(str, ",");
                } else {
                    str = string.concat(str, "]");
                }
            }
            if (i < 4) {
                str = string.concat(str, ",");
            } else {
                str = string.concat(str, "]");
            }
        }
        prism[id] = str;
    }

    function xe(uint256 id) external onlyHolder(id) {
        require(redacted[id] == 0);
        require(level[id] == 100);
        require(
            keccak256(abi.encodePacked(prism[id])) ==
                0x18dd307dad56bbc1962747ba3045a38d4d58443f58f1cc44ef53fb0c22e75bdf
        );
        require(block.timestamp % 5256000 > 5169600);
        redacted[id] = 1;
    }

    function invert(uint256 id) external onlyHolder(id) {
        if (spin[id] == 0) {
            spin[id] = 1;
        } else {
            spin[id] = 0;
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        Params memory params = Params(
            id,
            seed[id],
            prestige[id],
            prism[id],
            ownerOf(id),
            spin[id],
            level[id],
            redacted[id]
        );

        return program.uri(params);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        if (level[id] < 100) {
            ++level[id];
        }
        super.transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        if (level[id] < 100) {
            ++level[id];
        }
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override {
        if (level[id] < 100) {
            ++level[id];
        }
        super.safeTransferFrom(from, to, id, data);
    }

    function _prandom(uint256 id) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), id))
            );
    }

    function withdraw() external {
        require(msg.sender == owner);
        (bool succ, ) = owner.call{value: address(this).balance}("");
        require(succ);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f ||
            interfaceId == 0x2a55205a;
    }
}