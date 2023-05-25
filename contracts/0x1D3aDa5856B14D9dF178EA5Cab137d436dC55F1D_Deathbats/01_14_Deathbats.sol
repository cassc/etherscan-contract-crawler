// SPDX-License-Identifier: MIT
/******
 ______   _______  _______ _________          ______   _______ _________ _______
(  __  \ (  ____ \(  ___  )\__   __/|\     /|(  ___ \ (  ___  )\__   __/(  ____ \
| (  \  )| (    \/| (   ) |   ) (   | )   ( || (   ) )| (   ) |   ) (   | (    \/
| |   ) || (__    | (___) |   | |   | (___) || (__/ / | (___) |   | |   | (_____
| |   | ||  __)   |  ___  |   | |   |  ___  ||  __ (  |  ___  |   | |   (_____  )
| |   ) || (      | (   ) |   | |   | (   ) || (  \ \ | (   ) |   | |         ) |
| (__/  )| (____/\| )   ( |   | |   | )   ( || )___) )| )   ( |   | |   /\____) |
(______/ (_______/|/     \|   )_(   |/     \||/ \___/ |/     \|   )_(   \_______)

.....................,,...,.............................      ............,..,......,,.................,,.,,,,,,,...,...
........................,,....................   (@@@@@@@@@@@@@%%%%%/   .....................,,........,...,,,,,,,,.,...
..................,....,,,,,,,,.,.,.......  @@@@@@@@@@@@@@@@@@@@@@@@@@%%%%.  .......,.,,..,,,,,........,,,,,,,,,,,,..,..
.............,,,,,.,,,.,,,,,,..,,..,,.. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%  ......   %%%%%%%%%%%%%   ,,,,,,,,.,..,..
..............,,,,,,,,,,,,.,.,...... [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%% ....... %%%%..%        %%   ,,,.......
.............,..,,,,,,,,,,,..,...,  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%% ..  .%  %  %   %.        %% ...,....
..............,,,,,,,,.,,,,,,,,., @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%%%%       %   %%    %         % .,,,,,
.........,.....,,,,,,,,.,,.,,,,, @@@@@@@@@@@@@@@@@@@@@%%   @@@@@@@@@@@@@@@@@@@@@@@%%%%      %.    %     %         % ,,,,
................,,,,,,.   %%  ,  @@@@@@@@@@@@@@@@@%%% ,@@@@@@@@@@@@@@@@@@@@@@@#    %%%%     %/     %                  .,
........,,,,,,,.,.  %%..%%%% ., @@@@@@@@@@@@@@@&%%% @@@@@         %  @@@@@@        /%  .    %       %   .    ..,.,.,. .,
........,..,.,  %%    %  % ( %% @@@@@@@@@@@@@@@%%%. @@@%           .%  @@            %%     %    ...  ........,,,.,,....
,....,.,,.,. %%     %   #  %    @@@@@@@@@@@@@@%%%%% @@@       %@    %%, @     (@@    %%%    %  ,,.................,,,...
........,  %.     %   .%   %.    @@@@@@@@%%%%%%%%%%  @@             %% @@            %%% .,.  ,,.,..,..,.........,,.....
,,...,.  %       %    %     %    [email protected]@@@@%%%%%%%%%%%%% (@@/          %% @@/@          %%  %  ..,....,..,...,.,.....,,.....
.....  %%       .    %/     %      @@@@%%%%,   /%%%  @@@@@@         @@  %% (@        @@@@%% ...................,........
.... %%        ,     %       %      @@@@. @@@@@@@@@@@@@@@@@@@@@@@@@@       %( @@@@@@@@@@%%  ................,..,.,.,....
.., %%        %      %       %/   ,,, #@@@@@@@  @@@@@@@@@@@( @@@@@@         %% @@@@@%%%%  ..............................
.. %%                  ,,,,,    ,,,,,,,,,  ,, ,,,.        ,, [email protected]@@@@           @@@%  .,,.................................
.. %    .,,,, ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    .,,,,,,. %%%%%@%%       *    ,,.,,,,.............,.................
. ,  ..........,,,,,,,,,,,,,,,,,,,,,,,,,,, #@@@ [email protected]@&%# ,,,,,, [email protected]@@%  @@%% @@% @@&% .,.,.................................
.   ..............,,,,,,,,,,,,,,,,,,,,,,,,  @@@@@%%%  ,,,,,,,[email protected]@@@% @@@@% @@&% @@%( ....,,..............................
. ...................,..,,.,,,,,,,,,,,,,,,,,,  @@%.,,,,,,,,,, @@@@  [email protected]@@  @&       ...,,,...............................
......................,....,,,,,,,,,,,,,,,,,,, ,@@% ,,,,,,,,,                    .......................................
..........................,.,,,,,,,,,,,,,,,,,,, @@@%  ,,,,,, @@@%/ @@@%. @@% %@@% ......................................
.........,..................,,...,..,,,,,,,,,,,, @@@@%%%*  .% @@%% @@@% @@@% @@%........................................
...............................,.......,,,,,,,,,, @@@@@@@@@@@%%.  %  .#    *    * ......................................
........................,................,,,,,,,,,,  (@@@@ %@@@@@@@@@@  @@@@@@@%  ,.....................................
.................................................,,.....,,,,,  @@@@@%% @@@@@@@%  .......................................
...........................................,.............,,.,,,.     ....     ........................................
******/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Deathbats is ERC721Enumerable, Ownable {

    uint256 public constant MAX_BATS = 10000;
    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant RESERVED_BATS = 705;
    uint256 public constant MAX_MINT = 3;

    mapping(address => uint256) public totalMinted;
    string public baseURI;
    bool public baseURIFinal;
    bool public publicSaleActive;
    bool public presaleActive;

    bytes32 private _presaleMerkleRoot;
    mapping(address => bool) private _operatorBlocked;

    event BaseURIChanged(string baseURI);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory _initialBaseURI) ERC721("Deathbats Club", "DBC")  {
        baseURI = _initialBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!baseURIFinal, "Base URL is unchangeable");
        baseURI = _newBaseURI;
        emit BaseURIChanged(baseURI);
    }

    function finalizeBaseURI() external onlyOwner {
        baseURIFinal = true;
    }

    function emitPermanent(uint256 tokenId) external onlyOwner {
        require(baseURIFinal, "Base URL must be finalized first");
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _presaleMerkleRoot = _merkleRoot;
    }

    function setOperatorBlocked(address operator, bool blocked) external onlyOwner {
        _operatorBlocked[operator] = blocked;
    }

    function isOperatorBlocked(address operator) public view onlyOwner returns (bool) {
        return _operatorBlocked[operator];
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        (bool success,) = _to.call{value : _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function mintReserved(address _to, uint256 _batCount) external onlyOwner {
        require(totalMinted[msg.sender] + _batCount <= RESERVED_BATS, "All Reserved Bats have been minted");
        _mintBat(_to, _batCount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool){
        if (_operatorBlocked[operator]) {
            return false;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (_operatorBlocked[_msgSender()]) {
            return address(0);
        }
        return super.getApproved(tokenId);
    }

    function _verifyPresaleEligible(address _account, uint8 _maxAllowed, bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_account, _maxAllowed));
        return MerkleProof.verify(_merkleProof, _presaleMerkleRoot, node);
    }

    function mintBatPresale(uint256 _batCount, uint8 _maxAllowed, bytes32[] calldata _merkleProof) external payable {
        require(presaleActive && !publicSaleActive, "Presale sale is not active");
        require(_verifyPresaleEligible(msg.sender, _maxAllowed, _merkleProof), "Address not found in presale allow list");
        require(totalMinted[msg.sender] + _batCount <= uint256(_maxAllowed), "Purchase exceeds max presale mint count");
        require(PRICE * _batCount == msg.value, "ETH amount is incorrect");

        _mintBat(msg.sender, _batCount);
    }

    function mintBat(uint256 _batCount) external payable {
        require(publicSaleActive, "Public sale is not active");
        require(totalMinted[msg.sender] + _batCount <= MAX_MINT, "Purchase exceeds max mint count");
        require(PRICE * _batCount == msg.value, "ETH amount is incorrect");

        _mintBat(msg.sender, _batCount);
    }

    function _mintBat(address _to, uint256 _batCount) private {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _batCount <= MAX_BATS, "All Bats have been minted.");
        require(_batCount > 0, "Must mint at least one bat");

        for (uint256 i = 1; i <= _batCount; i++) {
            totalMinted[msg.sender] += 1;
            _safeMint(_to, totalSupply + i);
        }
    }
}