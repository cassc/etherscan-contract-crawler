pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* 

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM
Nk,'cooooooooooolcOWMMMMMMWKl,cooooooooooo:oXMMMMMMMMMMMMMMMMMN0xd0MMMMMMMMMMMMMMMMMMMMMMMMXkddddddddddddddddxxxxxxdclxkkxxxxkkkkkkxxxxxxkk0NN0ddkOxOO
O' .:dx0KKKKKKKKKolKMMMMMM0;.:0KKKKKKKKOxo;lXMMMMMMMMMMMMMMNKOkkkx0MMMMMMMMMMMMMMMMMMMMMMWk,.o0KKKKKKKKKKKKKKK000OxllxOdc:lkKOdok0KKkl;;ooOdokOOOdlOOO
O'    .;kKKKKKKKK0ldNMMMMXc.'kKKKKKKKKx;..:OWMWNXKKKXXNWWKdlxOKK0dxKK00XWNKKKXNNKK00KNWMM0,.c0KKKKKK00OOOOO0KKKKKd;l0Kkc;. 'lod0KKKx' .:cxKKd;oddXOooo
NOxo;  .lKK00KKKKKklkWMMWx..dKK0KKKKKKo:d0NWX00000O0000K0c.'kKKKKOkkkdlxdldkkkkkkkkkkxkXKc.cOK0kdl:,'.....,d0KKKk,,kKKOdOO; .cOKKKx. ,O0dkKK0:'xWMMMMM
MMMMK, .oK0dd0KKKKKdl0MM0'.c0Kdd0KKKKKdlKMXkxOKKkl:oOKKKO: 'kKKK0dcclldl;dKKKOOO0KKKKKxl,  'cc,...,;::'  .o0KKKKl.,OKKKkxX0, :0KKO, 'OXxxKKK0:.cNMMMMM
MMMMK, .dK0:,xKKKKK0ooXX:.;OKx,:0KKKKKdl00ld0KKOdc.'xKKKKl.'kKKK0l'',l:.cxoc:'.':x0KKK0l'.  .:okKXNWNk,.;kKKKKKKl..dKKKKxxXk.'xKKd..dXxx0KKKx. lNMMMMM
MMMMO' .xKO; ;OKKKKKOlol..xKO: ,OKKKKKxld::OKKKkO0xk00kol;.'kKKK0xOXXk,.;clllodxkOKKKK0dO0xkXWMMMMMXo..l0KKKKKKk:. .o0KK0kxx;.cx0k;,dxx0KK0d' 'OMMMMMM
MMMMk. 'kKk' .c0KKKKKk;..lKKl. 'kKKKKKkc,.c0KKKOO0Oxoolld:.'kKKK0x0MMNkldk0KK0dc,:kKKK0dOMMMMMMMMW0;.,xKKKKKK0dlkk; .,ok00Okxdl;:odxkO0Oxl,. ;OWMMMMMM
MMMWx. ,OKx'  .dKKKKKKo.:OKx'  .xKKKKKO:. :0KKKKKkdk0NNX0l.'kKKK0xkWNx,l0KKKKdl;..dKKK0dOMMMMMMMNd..cOKKKKKKkloKWMXx:...',;;:clxkdc:;,'....:xXMMMMMMMM
MMMWo. :0Kd;.  ,kKKKKK0xOKOl:. .xKKKKK0c. .xKKKKK00000000d..oKKKK0kko..xKKKKKkxo,:kKKKKxkNMMMMW0:.,xKKKKKK0dcxNMMMMMWKOxoodxOXWMMMWXOkxxk0XWMMMMMMMMMM
MMMNl  c0Kolx,  :OKKKKKKK0ook, .dKKKKK0l:' 'xKKKKKKKKKKK0d' .lOKKKK0l..c0KKKKK0OxxkKKKKklkNMMNx'.cOKKKKKKOll0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMNc .lKKloXx. .l0KKKKKKdl0K; .oKKKKKKook; .:dOKKKKKOkk0Xk;  .:oxOOo'  ,okOOkoc,..ldl:;:kNMKc.'d0KKKKK0xlxXMMMMMMWXkOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMX: .oK0ldNNl  .lOKKKKkckWX:  lKKKKKKooXXd;...,;::cokXWMMNkc,....,lOd'. .';lxOx,.,ldk0NMWk,.:kKKKKKKOolOWMMMMMWKxooolxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMK, .xK0ldWMXc   .,:clcdNMNc  cKKKKKKdl0MMNKkdodxOKWMMMMMMMWNKOxoxXMMNOxxk0NMMWK0NWMMMMXl..o0KKKKKKk:;okkkkkkxddx0KxcdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MWXd..l0KKdlkKXXkc;'.  .lXWN0c.'xKKKKKKOooOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.;kKKKKKKKKOxxxxxxxxkk0KKKxckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
k:;ldkKKKKKkdockWWWNKOk0NKo;codOKKKKKKKK0kdloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo. ;OKKKKKKKKKKKKKKKKKKKKKKKxcOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
. .ldddddddddo;xWMMMMMMMNc  ;oddddddddddddd:cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.  .ckkkkkkkkkkkkkkkkkkkkkkdcxWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
             .c0MMMMMMMMX:                .'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.   ......................,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
:;;;;;;;;;;;:dXMMMMMMMMMNx:;;;;;;;;;;;;;;;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'.......................,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMM

*/

//// @author:  Blockchain platform powered by Ether Cards - https://ether.cards

contract MetaZooGames is ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 public sales_end;

    modifier onlyAllowed() {
        require(
            permitted[msg.sender] || (msg.sender == owner()),
            "Unauthorised"
        );
        _;
    }

    constructor(uint256 _sales_start) ERC721("MetaZoo Games Tokens", "MZGT") {
        sales_end = _sales_start + 12 hours;
    }

    mapping(address => bool) public permitted;
    bool public saleLock = true;

    string public localBaseURL =
        "https://metazoo-metadata-server.herokuapp.com/api/metadata/";

    function _baseURI() internal view override returns (string memory) {
        return localBaseURL;
    }

    function setDataFolder(string memory __baseURI) public onlyOwner {
        localBaseURL = __baseURI;
    }

    function lockStatus() public view returns (bool) {
        return (sales_end >= block.timestamp || totalSupply() == 5000);
    }

    function endSales() public onlyOwner {
        // To trigger when sales over.
        sales_end = block.timestamp;
    }

    function contractURI() public view returns (string memory) {
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI(), "contract.json"));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // reformat to directory structure as below
        string memory file = tokenId.toString();
        return string(abi.encodePacked(_baseURI(), file));
    }

    // https://metazoo-metadata-server.herokuapp.com/api/metadata/<id>

    function setAllowed(address _addr, bool _state) external onlyOwner {
        permitted[_addr] = _state;
    }

    function mintCards(uint256 numberOfCards, address recipient)
        external
        onlyAllowed
    {
        // check the max is 5k.
        uint256 currentCount = totalSupply();
        require(currentCount + numberOfCards <= 5000, "Max supply");
        for (uint256 i = 1; i <= numberOfCards; i++) {
            _mint(recipient, currentCount + i);
        }
    }

    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        if (lockStatus()) {
            // if lock , cannot transfer.
            if (_from == address(0)) {
                // Do transfer Sales part,
                ERC721Enumerable._beforeTokenTransfer(_from, _to, _tokenId);
            } else {
                revert("saleLock");
            }
        } else {
            // normal after sales.
            ERC721Enumerable._beforeTokenTransfer(_from, _to, _tokenId);
        }
    }
}