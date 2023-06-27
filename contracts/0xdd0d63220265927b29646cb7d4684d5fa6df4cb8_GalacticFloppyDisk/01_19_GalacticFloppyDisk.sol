pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'base64-sol/base64.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import './SVGBuilder.sol';
import './HexStrings.sol';
import './ToColor.sol';

// External Contracts Interfaces
abstract contract NFTContract {
  function balanceOf(address owner) external virtual view returns (uint256);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

struct CoolSoftware {
  NFTContract contractInterface;
  string contractName;
  string softwareName;
}

struct BoringSoftware {
  string softwareName;
  uint256 diskCount;
  uint256 diskNumber;
}

contract GalacticFloppyDisk is Ownable, ERC721Enumerable {
  using Counters for Counters.Counter;
  using Strings for uint256;
  using Strings for uint8;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using SafeMath for uint256;

  Counters.Counter private _tokenCounter;
  CoolSoftware[] private coolSoftware;

  /// Immutable Storage
  uint256 public immutable AVAILABLE_SUPPLY;
  uint256 public immutable MAX_PER_ADDRESS;
  uint16 private immutable WACKY_THRESHHOLD;
  uint16 private immutable INSECURE_THRESHHOLD;
  uint16 private immutable INFECTED_THRESHHOLD;

  // Mutable Storage
  bool private saleActive = true;
  mapping(uint256 => bytes32) private genes;


  /// Events
  event FloppyMinted(address indexed user, uint256 mintIndex);
  event SaleStateFlipped(bool active);
  event ContractSet(string contractName);

  constructor(
    string memory _NFT_NAME,
    string memory _NFT_SYMBOL,
    uint256 _MAX_PER_ADDRESS,
    uint256 _AVAILABLE_SUPPLY,
    uint16 _WACKY_THRESHHOLD,
    uint16 _INSECURE_THRESHHOLD,
    uint16 _INFECTED_THRESHHOLD
  )
    ERC721(
      _NFT_NAME, _NFT_SYMBOL
    )

  {
    MAX_PER_ADDRESS = _MAX_PER_ADDRESS;
    AVAILABLE_SUPPLY = _AVAILABLE_SUPPLY;
    WACKY_THRESHHOLD = _WACKY_THRESHHOLD;
    INSECURE_THRESHHOLD = _INSECURE_THRESHHOLD;
    INFECTED_THRESHHOLD = _INFECTED_THRESHHOLD;
  }

  function flipSaleState() public onlyOwner {
    saleActive = !saleActive;
    emit SaleStateFlipped(saleActive);
  }

  function setNFTContract(address contractAddress, string memory contractName, string memory softwareName) public onlyOwner {
    coolSoftware.push(CoolSoftware({
      contractInterface: NFTContract(contractAddress),
      contractName: contractName,
      softwareName: softwareName
    }));
    emit ContractSet(contractName);
  }

  function getNFTContracts() public view onlyOwner returns (CoolSoftware[] memory) {
    return coolSoftware;
  }

  function clearNFTContracts() public onlyOwner {
    delete coolSoftware;
  }

  function mint() external {
    uint256 id = _tokenCounter.current();
    uint256 _newAmountMinted = id.add(1);
    uint256 _walletOwns = balanceOf(_msgSender());
    uint256 _newWalletOwns = _walletOwns.add(1);

    require(saleActive,                           "Sale must be active");
    require(_newAmountMinted <= AVAILABLE_SUPPLY, "We ran out of floppies");
    require(_newWalletOwns  <= MAX_PER_ADDRESS,   "Max floppy disks obtained");

    _safeMint(msg.sender, id);
    _tokenCounter.increment();

    // Generate 32 bytes of "random" data by hashing some things
    genes[id] = keccak256(abi.encodePacked(
      block.timestamp,
      block.difficulty,
      id,
      _msgSender(),
      address(this)
    ));

    emit FloppyMinted(_msgSender(), id);
  }

  function getColors(bytes32 gene) internal pure returns (colorSet memory) {
    return colorSet({
      color1: bytes3(
        bytes2(gene[0]) |
        bytes2(gene[1]) >> 8 |
        bytes3(gene[2]) >> 16
      ),
      color2: bytes3(
        bytes2(gene[3]) |
        bytes2(gene[4]) >> 8 |
        bytes3(gene[5]) >> 16
      ),
      color3: bytes3(
        bytes2(gene[6]) |
        bytes2(gene[7]) >> 8 |
        bytes3(gene[8]) >> 16
      ),
      color4: bytes3(
        bytes2(gene[9]) |
        bytes2(gene[10]) >> 8 |
        bytes3(gene[11]) >> 16
      ),
      color5: bytes3(
        bytes2(gene[12]) |
        bytes2(gene[13]) >> 8 |
        bytes3(gene[14]) >> 16
      )
    });
  }

  function isDiskInsecure(bytes32 gene, uint256 threshhold) internal pure returns (bool) {
    uint16 insecureDisk = uint16(
      uint8(gene[17]) |
      uint16(uint8(gene[18])) << 8
    );
    return insecureDisk > threshhold ? true : false;
  }

  function getInitialSoftware(bytes32 gene) internal pure returns (BoringSoftware[2] memory) {
    string[68] memory boringSoftware = [
      "WordPerfect 5.1", "Lotus 123 3.1+", "Norton Cmmndr [CRK]", "Qmodem 4.5 (DOS)", "FreePascal GO32v2",
      "Wildcat BBS 4", "ACiDDraw v0.05", "mouse.com", "BIORYTHYMICATOR", "386 TeST", "GORILLAS.BAS", "WordStar",
      "X-Tree Gold", "ProComm Plus", "dBase 3", "pkzip.exe", "QEMM", "Dazzle", "Norton Ghost", "Zmodem",
      "IceModem", "ARJ", "LapLink3", "NeoPaint", "quickmenu III", "MS-DOS 6.22", "iMPULSE TRaCKeR",
      "Commander KEEN", "GWBasic", "ALF", "ZZT", "NetHack", "Iniquity BBS", "LoRD", "Borland TurboC",
      "Norton Utilities", "FoxPro", "Print Shop Pro", "Quattro Pro", "Renegade BBS", "Spinrite",
      "Telegard", "Turbo Assembler", "XTree", "GALACT~1.EXE", "King's Quest 2", "Scortched Earth", "Lemmings",
      "ZORK", "California Games", "Hexen", "Rise of the Triad", "Prince of Persia", "SimCity",
      "Space Quest", "black cauldron", "jumpman", "battle chess", "warcraft", "ultima 5",
      "nethack", "syndicate", "alone in the dark", "secret of monkey island",
      "x-wing tie figther", "stronghold", "civ", "Arkanoid"
    ];
    BoringSoftware[2] memory initialSoftware;
    uint boringSoftwares = (uint8(
      gene[21]
    ) % 2) + 1; // How many boring softwares are ALWAYS on the disk.

    // Pick some rando boring software
    for (uint256 i = 0; i < boringSoftwares; i++) {
      uint256 boringIdx = (uint8(gene[22 + i])) % boringSoftware.length;
      // Max 12 disks - same software always has the same # of disks
      uint8 diskCount = (uint8(boringIdx) % 11) + 1;
      initialSoftware[i] = BoringSoftware({
        softwareName: boringSoftware[boringIdx],
        diskCount: diskCount,
        diskNumber: (uint8(gene[23 + i]) % diskCount)+ 1
      });
    }
    return initialSoftware;
  }

  function getPattern(bytes32 gene, uint256 threshhold) internal pure returns (uint8 patternId) {
    uint16 wackyPattern = uint16(
      uint8(gene[19]) |
      uint16(uint8(gene[20])) << 8
    );
    return wackyPattern > threshhold ? uint8(wackyPattern % 3) + 1 : 0;
  }

  function getVirus(bytes32 gene, uint256 threshhold) internal pure returns (string memory virusName) {
    string[18] memory viruses = [
      "Michaelangelo", "Europe-92",
      "Leandro", "STONED",
      "DOS.Casino", "BRAiN",
      "DOS.Walker", "Natas",
      "911 Virus", "Hare",
      "Yankee Doodle", "OneHalf",
      "MkS_vir", "GhostBall",
      "Elvira", "Ambulence",
      "Ithaqua", "Cascade"
    ];
    // Use the first, second, and third bytes of "gene data" to
    // produce a 24 bit value representing an RBG color. This
    uint16 infectedDisk = uint16(
      uint8(gene[15]) |
      uint16(uint8(gene[16])) << 8
    );
    return infectedDisk > threshhold ? viruses[infectedDisk % viruses.length] : '';
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "not exist");
    address owner = ownerOf(id);
    bytes32 gene = genes[id];
    uint8 pattern = getPattern(gene, WACKY_THRESHHOLD);
    bool insecure = isDiskInsecure(gene, INSECURE_THRESHHOLD);
    string memory virusName = getVirus(gene, INFECTED_THRESHHOLD);
    colorSet memory colors = getColors(gene);

    FileListing memory files = getFiles(owner, getInitialSoftware(gene), insecure, virusName);
    string memory traits = getTraits(colors, files, insecure, pattern, virusName);
    string memory image = Base64.encode(bytes(SVGBuilder.generateSVGofToken(colors, files, pattern)));

    return
        string(
            abi.encodePacked(
              'data:application/json;base64,',
              Base64.encode(
                  bytes(
                        abi.encodePacked(
                            '{"name":"',
                            string(abi.encodePacked('Galactic Floppy #', id.toString())),
                            '", "description":"',
                            'This Floppy Is Radical!',
                            '", "external_url":"https://floppy.galactic.io/?token=',
                            id.toString(),
                            '", "attributes": [',
                            traits,
                            '], "owner":"',
                            uint160(owner).toHexString(20),
                            '", "image": "',
                            'data:image/svg+xml;base64,',
                            image,
                            '"}'
                        )
                      )
                  )
            )
        );
  }

  function getTraits(colorSet memory tokenColors, FileListing memory files, bool isInsecure, uint256 wackyPattern, string memory infectedWith) internal pure returns (string memory) {
    string memory traits = string(abi.encodePacked(
      '{"trait_type": "Disk Color", "value": "',tokenColors.color1.toColor(),'"},',
      '{"trait_type": "Label Color", "value": "',tokenColors.color2.toColor(),'"}'
    ));

    for (uint256 i = 0; i < files.boringSoftwares.length; i++) {
      if (bytes(files.boringSoftwares[i]).length > 0) {
        traits = string(abi.encodePacked(
          traits,
          ",",
          '{"trait_type": "',
          string(abi.encodePacked("BoringFile", i.toString())),
          '", "value": "',
          files.boringSoftwares[i],
          '"}'
        ));
      }
    }

    for (uint256 i = 0; i < files.specialSoftwares.length; i++) {
      if (bytes(files.specialSoftwares[i]).length > 0) {
        traits = string(abi.encodePacked(
          traits,
          ",",
          '{"trait_type": "',
          string(abi.encodePacked("CoolFile", i.toString())),
          '", "value": "',
          files.specialSoftwares[i],
          '"}'
        ));
      }
    }

    if (isInsecure) {
      traits = string(abi.encodePacked(
        traits,
        ",",
        '{"trait_type": "Insecure Disk", "value": "true"}'
      ));
    }
    if (bytes(infectedWith).length > 0) {
      traits = string(abi.encodePacked(
        traits,
        ",",
        '{"trait_type": "Has Virus", "value": "',infectedWith,'"}'
      ));
    }
    if (wackyPattern > 0) {
      string memory wackyPatternName;
      if (wackyPattern == 1) {
        wackyPatternName = "Crosses";
      } else if (wackyPattern == 2) {
        wackyPatternName = "Ombre";
      } else if (wackyPattern == 3) {
        wackyPatternName = "Polka Dot";
      }
      traits = string(abi.encodePacked(
        traits,
        ",",
        '{"trait_type": "Wacky Pattern", "value": "',wackyPatternName,'"}'
      ));
    }
    return traits;
  }

  function getFiles(address owner, BoringSoftware[2] memory initialSoftware, bool isInsecure, string memory infectedWith) internal view returns (FileListing memory) {
    uint256 fileCount;
    uint256 yPos;
    FileListing memory fl;

    for (uint256 i = 0; i < initialSoftware.length; i++) {
      yPos = fileCount * 23 + 32;
      if (bytes(initialSoftware[i].softwareName).length > 0) {
        fl.textElements = string(abi.encodePacked(
          fl.textElements,
          "<text class='t' x='49' y='",
          yPos.toString(),
          "'>* ",
          initialSoftware[i].softwareName,
          " disk ",
          initialSoftware[i].diskNumber.toString(),
          "/",
          initialSoftware[i].diskCount.toString(),
          "</text>"
        ));
        fl.boringSoftwares[i] = initialSoftware[i].softwareName;
        fileCount++;
      }
    }

    if (isInsecure) {
      yPos = fileCount * 23 + 32;
      fl.textElements = string(abi.encodePacked(
        fl.textElements,
        "<text class='t' x='49' y='",yPos.toString(),"'>* mnemonic.txt</text>"
      ));
      fileCount++;
    }

    for (uint256 i = 0; i < coolSoftware.length; i++) {
      uint256 ownerBalance = coolSoftware[i].contractInterface.balanceOf(owner);
      if (ownerBalance > 0) {
        if (fileCount < 7) {
          yPos = fileCount * 23 + 32;
          fl.textElements = string(abi.encodePacked(
            fl.textElements,
            "<text class='t' x='49' y='",
            yPos.toString(),
            "'>* ",
            coolSoftware[i].softwareName,
            "</text>"
          ));
          fl.specialSoftwares[i] = coolSoftware[i].softwareName;
          fileCount++;
        }
      }
    }

    if (bytes(infectedWith).length > 0) {
      fl.textElements = string(abi.encodePacked(
        fl.textElements,
        "<text x='110' y='100' style='fill: rgb(255, 100, 100); font-family: saserif; font-size: 28px; white-space: pre; font-style: italic; font-weight: bold;' stroke-width='1' stroke='#0b000099' text-anchor='middle' dominant-baseline='central' transform='rotate(-25 100 0)'><tspan>Infected with</tspan><tspan x='100' y='130'>",
        infectedWith,
        "!!</tspan></text>"
      ));
    }

    return fl;
  }

  function withdrawERC20(IERC20 token) public onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
}