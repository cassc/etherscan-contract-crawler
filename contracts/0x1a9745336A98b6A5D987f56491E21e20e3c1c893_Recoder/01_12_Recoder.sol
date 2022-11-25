//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**

`7MM"""YMM   .M"""bgd `7MN.   `7MF'`YMM'   `MP'
  MM    `7  ,MI    "Y   MMN.    M    VMb.  ,P
  MM   d    `MMb.       M YMb   M     `MM.M'
  MMmmMM      `YMMNq.   M  `MN. M       MMb
  MM   Y  , .     `MM   M   `MM.M     ,M'`Mb.
  MM     ,M Mb     dM   M     YMM    ,P   `MM.
.JMMmmmmMMM P"Ybmmd"  .JML.    YM  .MM:.  .:MMa.

powered by ctor.xyz

 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

interface ICode {
    function burn(
        address acount,
        uint256 id,
        uint256 value
    ) external;
}

interface IShell {
    function nextTokenId() external returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to, uint256 quantity) external;
}

interface IEsnxComponent {
    function mint(address to) external;
}

interface ICodec {
    function mint(address to, uint256 quantity) external;
}

contract Recoder is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address public immutable signer;

    ICode public immutable code;
    IShell public immutable shell;
    address public immutable valhalla;

    IEsnxComponent public esnxComponent;
    ICodec public codec;

    uint256 public recodingStartTime;
    uint256 public recodingEndTime;

    event Recode(uint256 indexed newShellTokenId, address indexed to);

    error NotEOA();
    error NotStarted();
    error Ended();
    error InvalidTime();

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    modifier onlyDuring(uint256 startTime, uint256 endTime) {
        uint256 blockTime = block.timestamp;
        if (blockTime < startTime) {
            revert NotStarted();
        }
        if (blockTime >= endTime) {
            revert Ended();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address code_,
        address shell_,
        address valhalla_
    ) {
        _disableInitializers();

        signer = owner();

        code = ICode(code_);
        shell = IShell(shell_);
        valhalla = valhalla_;
    }

    function initialize() external initializer {
        __Ownable_init();

        recodingStartTime = type(uint256).max;
        recodingEndTime = type(uint256).max;
    }

    function setEsnxComponent(address esnxComponent_) external onlyOwner {
        esnxComponent = IEsnxComponent(esnxComponent_);
    }

    function setCodec(address codec_) external onlyOwner {
        codec = ICodec(codec_);
    }

    function setRecodingTime(uint256 start, uint256 end) external onlyOwner {
        if (end <= start) {
            revert InvalidTime();
        }
        recodingStartTime = start;
        recodingEndTime = end;
    }

    function recode(uint256 shellTokenId, uint256 codeTokenId)
        external
        onlyDuring(recodingStartTime, recodingEndTime)
        onlyEOA
    {
        code.burn(msg.sender, codeTokenId, 1);
        shell.transferFrom(msg.sender, valhalla, shellTokenId);

        uint256 newShellTokenId = shell.nextTokenId();
        shell.mint(valhalla, 1);

        esnxComponent.mint(msg.sender);

        codec.mint(msg.sender, 1);

        emit Recode(newShellTokenId, msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}