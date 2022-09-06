// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*
MNK0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000KNM
MO'..   ................................   .... ..... ..  ...  ................................. 'kM
Mk.                                           ......,;;,'.                                       .kM
Mk.                                     .;ldk0KXXXXNWMWWNKOdc,.                                  .kM
Mk.                                 .;oOXWMMMMMMMMMMMMMMMMMMMWKx:.                               .kM
Mk.                             .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:.                            .kM
Mk.                          'lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd'                          .kM
Mk.                        .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'                        .kM
Mk.                        lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0,                       .kM
Mk.                       ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                      .kM
Mk.                      .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                     .kM
Mk.                      ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                     .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .kM
Mk.                     oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                     .kM
Mk.                    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .kM
Mk.                    .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                     .kM
Mk.                    ,KMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                     .kM
Mk.                    lNMMMMMMM0l:;;;:lx0XWMMMMMMMMMMMMWMMMUNLEARNkNMMMMMNl                     .kM
Mk.                   .xMMMMMMMWl        ..:d0NMMMMMMNOo:'.        ,KMMMMMNc                     .kM
Mk.                    oWMMMMMMMk.           .;0MMMMK:             :XMMMMMK,                     .kM
Mk.                    '0MMMMMMMWk:..     ..';oKMMMMNxc,...     ..:0WMMMMWx.                     .kM
Mk.                     cXMMMMMMMMWXK0OOO00KNWMMMMMMMMMWXK00OOOO0XWMMMMMMX:                      .kM
Mk.                     .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                      .kM
Mk.                      .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                       .kM
Mk.                       :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                       .kM
Mk.                       .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                       .kM
Mk.                        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                        .kM
Mk.                         oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                        .kM
Mk.                         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                         .kM
Mk.                          '0MMMMMMMMMMMMMMWNK0000KKNWMMMMMMMMMMMMMXc                          .kM
Mk.                           lWMMMMMMMMMMW0l,...  ....;dXMMMMMMMMMMWd.                          .kM
Mk.                           ,KMMMMMMMMMMX;            .xMMMMMMMMMMNl                           .kM
Mk.                          .dNMMMMMMMMMMNl            ;0MMMMMMMMMMWo                           .kM
Mk.                         ;0WMMMMMMMMMMMMXd,.       'oKMMMMMMMMMMMWk.                          .kM
Mk.                       .lXMMMMMMMMMMMMMMMMN0xooooxOXWMMMMMMMMMMMMMW0l'                        .kM
Mk.                      ,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;                      .kM
Mk.                    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                    .kM
Mk.                    ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                    .kM
Mk.                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                    .kM
Mk.                     ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                    .kM
Mk.                      :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.                     .kM
Mk.                       ;ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;                       .kM
Mk.                        .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.                        .kM
Mk.                           .:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0o,                           .kM
Mk.                              .;ok0NWMMMMMMMMMMMMMMMMMMMMMWXOxc'.                             .kM
Mk.                                  ..;cldxkO0KKKKKK00Okxol:,.                                  .kM
MKocccccccccccccccccccccccccccccccccccccccccloodddddddollccccccccccccccccccccccccccccccccccccccccoKM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

// Everybody be cool! This is a robbery! https://twitter.com/BandOfCrazy
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract BandOfCrazy is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    event PaymentReceived(address from, uint256 amount);
    using Strings for uint256;

    struct Character {
        string name;
        uint16 supply;
        uint16 minted;
        uint16 lower;
        uint16 upper;
        uint256 cost;
        uint256 discount;
    }
    Character[] public characters; // store a list of character

    struct Tool {
        string name;
        uint16 count;
        uint16 ability;
        uint256 cost;
        uint256 tokens;
    }
    Tool[] public tools; // store a list of tools

    string private constant _name = "Band Of Crazy";
    string private constant _symbol = "BOC";
    string public baseURI = "https://ipfs.io/ipfs/QmWJPZraaS3ZcqsMYJhMU8QYNvRKYBukK62tVtst1yXaJx/";
    uint16[5] public maxMint = [0, 2, 6, 3, 3];
    uint16 public maxSupply = 3885;
    uint16[] public ability = [0]; //id starts at 1
    uint16[] public character = [0]; //id starts at 1
    bool[5] public phaseActive;
    bool public revealed = false;
    bytes32 public whitelistMerkleRoot;
	mapping(address => uint16[5]) public minted;
    mapping(uint16 => uint16) public left;
    mapping(uint16 => uint16) public right;
    mapping(uint16 => bool) public jailed;
    address public jailer = msg.sender;

    IERC20 public stakingToken20 = IERC20(0x05cd75f850E0ca64FF780f52B0AAC5558ae95265);

    constructor() ERC721A(_name, _symbol) payable {
        _setDefaultRoyalty(address(this), 1000);
        tools.push(Tool("None", 0, 1, 2, 3)); //0 tool is skipped
        characters.push(Character("None", 0, 0, 0, 0, 0, 0)); //0 character is skipped
    }

    // @dev to support payments
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // create characters
    function setup() external onlyOwner {
        characters.push(Character("The Driver", 555, 0, 2, 4, 0.03 ether, 0));
        characters.push(Character("The Thief", 555, 0, 4, 7, 0.03 ether, 0));
        characters.push(Character("The Inside Man", 555, 0, 7, 10, 0.06 ether, 0.03 ether));
        characters.push(Character("The Hacker", 555, 0, 10, 13, 0.06 ether, 0.03 ether));
        characters.push(Character("The Mastermind", 555, 0, 13, 16, 0.06 ether, 0.03 ether));
        characters.push(Character("The Phantom", 555, 0, 10, 13, 0.06 ether, 0.03 ether));
        characters.push(Character("The Wild Card", 555, 0, 7, 16, 0.06 ether, 0.03 ether));
    }

    // @dev added to support royalties 
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // @dev public minting of The Guv’nors Game
	function mint(address to, uint16 _mintAmount, bytes32[] calldata merkleProof, uint16 phase) external payable nonReentrant {
        uint16 _character;

        require(Address.isContract(msg.sender) == false, "Band: no contracts");
        require(totalSupply() + _mintAmount <= maxSupply, "Band: Cant mint more than max supply");
        if (phase == 0) {phase = 1;}
        require(phaseActive[phase], "Band: phase is paused");

        if (msg.sender != owner()) {
            require(minted[msg.sender][phase] + _mintAmount <= maxMint[phase], "Band: Must mint less than the max");
        }

        bool approved = isValidMerkleProof(msg.sender, merkleProof);

        //choose character to be minted
        _character = whichCharacter(phase, 10);

        if (msg.sender == owner()) {
            // This is used by the governer to pay out bribes to get you idiots out of jail.
        } else if (merkleProof.length == 0) {
            //proof not provided so full price
            require(msg.value >= characters[_character].cost * _mintAmount, "Band: You must register on premint or pay for the nft");
        } else if (approved == true) {
            //has registered at premint so give a discount, maybe even free
            require(msg.value >= characters[_character].discount * _mintAmount, "Band: Discounted price must be paid");
        } else {
            //has not registered so full price
            require(msg.value >= characters[_character].cost * _mintAmount, "Band: You must register on premint or pay for the nft");
        }

        // We don't want you crying to mummy about high gas fees do we?
        unchecked{
            minted[msg.sender][phase] += _mintAmount;
            for (uint16 i = 0; i < _mintAmount; i++) {

                //set the character and ability
                character.push(_character);
                ability.push(chooseAbility(_character, i));
                characters[_character].minted += 1;

                if (_mintAmount - i > 1) {
                    //choose next character if we are minting another one
                    _character = whichCharacter(phase, i);
                }
            }
        }

        // So you are a wise ass checking the contract eh? Is it safe enough for ya? 
        // You better check the ERC721A as well or do you need a bloody mastermind to hold your hand?
        _safeMint(to, _mintAmount);
    }

    // @dev If they not on the list, then charge em double.
    function isValidMerkleProof(address to, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(to)));
    }

    // @dev set presale root
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    // @dev If the Tosser is weak, he need a good slap.
    function setCharacter(uint16 id, string calldata _charName, uint16 _supply, uint16 _lower, uint16 _upper, uint256 _cost, uint256 _discount) external onlyOwner {
        /*
        require(bytes(_charName).length > 0, "Band: character must have a name");
        require(_supply > 0, "Band: character must have a count");
        require(_lower > 0, "Band: character must have lower");
        require(_upper > _lower, "Band: character must have an upper");
        */
        
        if (id == 0) {
            characters.push(Character(_charName, _supply, 0, _lower, _upper, _cost, _discount));
        } else {
            require(id < characters.length, "Band: character does not exist");

            characters[id].name = _charName;
            characters[id].supply = _supply;
            characters[id].lower = _lower;
            characters[id].upper = _upper;
            characters[id].cost = _cost;
            characters[id].discount = _discount;
        }
    }

    // @dev show the first 500 nft owned by an address, needed for better website performance
    function ownedList(address _owner) external view returns (uint16[7][500] memory list) {
        uint16 i;
        uint16 j;
        address nftOwner;
        uint256 ownerBalance;
        uint16[8] memory counts;
        // list[id, character, ability, left, right, jailed, characterCount]
        //      0    1          2         3       4       5       6

        unchecked {
            ownerBalance = balanceOf(_owner);

            //only check the first 500
            if (ownerBalance > 500) {
                ownerBalance = 500;
            }

            //find the list of id owned
            for (i = 1; i <= totalSupply(); i += 1) {
                nftOwner = ownerOf(i);
                if (nftOwner == _owner) {
                    list[j][0] = i;
                    j += 1;
                    if (j == ownerBalance) {
                        break;
                    }
                }
            }

            //record details for each nft            
            for (i = 0; i < ownerBalance; i += 1) {
                j = list[i][0];
                list[i][1] = character[j];
                list[i][2] = ability[j];
                list[i][3] = left[j];
                list[i][4] = right[j];
                list[i][5] = jailed[j] ? 1 : 0;
            }

            //find the count of each character ie nft id 86 could be the 13th Driver
            j = 0;
            for (i = 0; i < list[ownerBalance - 1][0]; i += 1) {
                counts[character[list[i][0]]] += 1;

                if ((i + 1) == list[i][0]) {
                    list[j][6] = counts[character[list[i][0]]];
                    j += 1;
                }
            }
        }

        return (list);
    }

    // @dev choose character to be minted based on phase of mint
	function whichCharacter(uint16 phase, uint16 count) internal view returns (uint16) {
        uint16 _character;

        unchecked{
            require(phase > 0 && phase < 5, "Band: phase is not valid");

            if (phase == 1) {
                //first 2 characters
                _character = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, phase * count * 10))) % 2) + 1;
                if (_character < 1 || _character > 2) {
                    _character = 1;
                }
                if (characters[_character].minted == characters[_character].supply) {
                    if (_character == 1) {
                        _character = 2;
                    } else {
                        _character = 1;
                    }
                }

            } else if (phase == 2) {
                //3rd, 4th, 5th characters
                _character = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, phase * count * 10))) % 3) + 3;
                if (_character < 3 || _character > 5) {
                    _character = 3;
                }
                if (characters[_character].minted == characters[_character].supply) {
                    if (characters[3].minted < characters[3].supply) {
                        _character = 3;
                    } else if (characters[4].minted < characters[4].supply) {
                        _character = 4;
                    } else {
                        _character = 5;
                    }
                }

            } else if (phase == 3) {
                //6th character
                _character = 6;

            } else if (phase == 4) {
                //7th character
                _character = 7;
            }
        }

        require(characters[_character].minted < characters[_character].supply, "Band: phase is sold out");
        return _character;
	}

    // @dev Bloody pick some rando number for this bloke.
    function chooseAbility(uint16 _character, uint16 count) internal view returns (uint16) {
        uint16 range;
        uint16 random;

        require(characters.length > _character, "Band: missing character data");
        
        unchecked {
            range = characters[_character].upper - characters[_character].lower + 1;
            random = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _character * count * 10))) % range) + characters[_character].lower;
        }

        return random;
    }

    // @dev tool has gotta have power.
    function setTool(uint16 id, string calldata _toolname, uint16 _count, uint16 _ability, uint256 _cost, uint256 _tokens) external onlyOwner {
        /*
        require(bytes(_toolname).length > 0, "Band: tool must have a name");
        require(_count > 0, "Band: tool must have a count");
        require(_cost > 0, "Band: tool must have a cost");
        require(_tokens > 0, "Band: tool must have a cost of tokens");
        require(_ability > 0, "Band: tool must have ability");
        */

        if (id == 0) {
            tools.push(Tool(_toolname, _count, _ability, _cost, _tokens));
        } else {
            require(id < tools.length, "Band: tool does not exist");
            tools[id].name = _toolname;
            tools[id].count = _count;
            tools[id].ability = _ability;
            tools[id].cost = _cost;
            tools[id].tokens = _tokens;
        }
    }

    // @dev show how many tools exist
    function toolCount() public view returns (uint256) {
        return tools.length;
    }

    // @dev A tosser needs to buy some tools.
    function buyTool(uint16 tool, uint16 id, bool withToken) external payable nonReentrant {
        require(id <= totalSupply() && id > 0, "Band: NFT does not exist");
        require(tool < tools.length && tool > 0, "Band: Tool does not exist");
        require(msg.sender == ownerOf(id) || msg.sender == owner(), "Band: You are not the owner of this NFT");
        require(tools[tool].count > 0, "Band: We are sold out of that tool");
        require(right[id] == 0, "Band: You can only buy 2 tools");

        if (msg.sender == owner()) {
            //free upgrade from the governer
        } else if (withToken) {
            require(stakingToken20.balanceOf(msg.sender) >= tools[tool].tokens, "Band: You don't have enough token balance");
            require(stakingToken20.allowance(msg.sender, address(this)) >= tools[tool].tokens, "Band: You must give allowance in the token to this NFT contract");
            stakingToken20.transferFrom(msg.sender, address(this), tools[tool].tokens);
        } else {
            require(msg.value >= tools[tool].cost, "Band: Must send cost of tool in eth");
        }

        //add the tool to the nft
        if (left[id] == 0) {
            left[id] = tool;
        } else {
            right[id] = tool;
        }

        //reduce supply of that sold tool
        tools[tool].count -= 1;
        //increase ability of that id
        ability[id] += tools[tool].ability;
    }

    // @dev max mint amount for paid nft
    function setMaxMint(uint16 _phase, uint16 _newMax) external onlyOwner {
	    maxMint[_phase] = _newMax;
	}

    // @dev set jailer address and token address
	function setJailer(address _jailer, address _token) external onlyOwner {
    	jailer = _jailer;
        stakingToken20 = IERC20(_token);
	}
	
    // @dev enable each phase
	function setPhase(uint16 id, bool _status) external onlyOwner {
    	phaseActive[id] = _status;
	}
	
    // @dev Set the base url path to the metadata used by opensea and set if revealed
    function setBaseURI(string memory _baseTokenURI, bool _revealed) external onlyOwner {
        baseURI = _baseTokenURI;
    	revealed = _revealed;
    }

    // @dev show the uri depending on whether it is revealed
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory uri;
        uint256 _char;

        if (revealed) {
            //show image of that nft
            uri = bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _tokenId.toString(),".json")) : '';
        } else {
            // show video of that nft's character
            _char = character[_tokenId];
            uri = bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _char.toString(),".json")) : '';
        }

        return uri;
    }

    // @dev Set the nft as jailed, to be used by the staking contract
    function setJail(uint16 id, bool _jail) external nonReentrant {
        require(id <= totalSupply() && id > 0, "Band: NFT does not exist");
        require(msg.sender == jailer, "Band: you are not the jailer");
        jailed[id] = _jail;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev allow to reduce max supply if needed
    function reduceMaxSupply(uint16 newMax) external onlyOwner {
        require(newMax < maxSupply, "Band: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "Band: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    // @dev set the royalty address and amount
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
    }
}
