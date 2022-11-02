// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
/*
                             =:                                                      :=
                             -*==.                   +==========                  .==*+
                              #:.-+=.               -*---------#.               -=-..#
                              :+...:=+:          .=+*+---------*++=-         -+=:...+-
  .%*++====++=----.            :+=....-==:     :++--*+---------+=---+=    :==:....=+:              --===+++==+++*%.
  ++===++====+++=:=+:            .=+-....-+#=:*+----*=---------=*----=#+#+-....-+=.             :+=:=+++====++===+-
   #--++=*----=--++:=+-             .=+-....=**-----**+++++++++*+----+*=:...-+=:              :+=:+*=-=----*=++--*
   .*-=#:-#=-#*##--++--+=              +*+=:..:++=----------------=++:...-++*-              -+--++--*#*#--*-:#=-+:
    .*-=*:-#-+###----=*=:+=            +=-=+*=:..-++------------++-..:=+%=--+=            =+:-*=----*##+-*=:*+-+-
     .*-=*++--------==-=*-:++.    -*#*=====+**%#+:.:*#********#%-.:=*%++*+====*#*-      =+:-*+-==--------=**=-*-
      .==+++=-------*%#*==+=:=+-:     =#++-:....:-+*##%*#######*##=:....:-=+#*.      .=+:=*+-+#%*-------==++==.
            .:-%%#*+--*##*==*=:=+:    .*=#+++++=:.=#*##++++++***#%+:=++++==#==     :+=.=*==*##*--+*#%%=:.
               [email protected]@@@@#=-*###==*=.=+-   *=-*+---=%++*%*+*#+++*%**#*+=*+---=#-==   :+=.=*==###*=-#@@@@@=
                .:=*@@@#+-*###+=*+:-+- +=--*+---+*:::+#**%*##***-::+*---+*--+- -+=:++=+###*-=#@@@*=-.
                     :#@@%+-+###*-++::+#+---++---+*++++#**%**#*+++**---+*---**+-:+*-+###+-+%@@#-
                       [email protected]@@*-+###*-++:-#=---+*---*=----+#%##=---=#---*+---=#-:+*=+###[email protected]@@*:
                         .#@@@*-+###*=#*=#+---#*---#-----=*+-----#---*#---=#-*#++###+-*@@@*:
                       -=-:[email protected]@@@*#%##****##*+#-+%=-#+++++++++++++#--#*=#+*###****###*%@@@@%%%*:
                       %     #@#+=----------#--%@@**----*++==#---**%@@--#=---------=+*#%*-###%#
                       ==   =#=------------++-*@@@@+=---*....++--=%@@@#--#-------------*%: .-%-
                        #  +*++++++++**+*%%%[email protected]@@@*==++#-....:%++=*%@@@+-+%%*++#+++++++++*- :%
                        --*=---------*=-#@@=-+%#=------%-....=%------*%*--%@%--#----------*==-
                         %+----------#--%@#--------+**+-+*==*==**[email protected]@--+*----------*%
                        =#---------=#*[email protected]@%+==+*#%@@=----#=#[email protected]@@%*+===*@@=--%+=---------%=
                       =%%###+++%[email protected]@@@@@@@@@@@-----#-++----%@@@@@@@@@@@=--# .-+#+++%#%%%-
                      =%##%%---*.   #---*%%%%%###**=----++--#-----+**##%%%%%#---+-   :*--=%###%:
                     +%###%+-*=     #------------===----#---*=---===------------==     =+-#%##%%:
                  -=+#*#%%@***:     #--+##%%%%%%%##*=--=*----#---*###%%%%%%##*---+     :**#%%%#*#==:
                .*=-----%%=--*-     #---=----------==+*+-----=*++=----------=---+=     :+--+%%-----=*.
               :#+++=--+#=---#       --==+*+++++++==%-----------#+=+++++++*+===-:       *---=#+--=+++#
              .%+++=---#----*-            *--==-=+--+*---------=#--=+-=+--#.            -=----#---=+++#
              #=------++----#             :*[email protected][email protected]=---%##++++###---%*-%*-=+              #----*=------++
             +*++++---%++--*:              +=-%*-*#---%+#::::#*#[email protected][email protected]#               =+--+*#---++++#-
            :*-------*%%%%#+                *-=*--*---%**::::**%--+=-+=-+-                ##%%#%=-------#
            ++++++=--%%###%+                -+--------%+#-::-%+#-------=*                 %%###%%--=++++*+
           .*-------#%####%+                 +=-------=#*#++#*#=-------#                  #%####%+-------#.
           .*------*%%%%%#=                   *=-=+----=#****#+----*+-#.                   +%%%%%%+------#.
            *=#*#%#+%==-.                   :*#%+-=*+==--=++=--==+*=-*##+-                   .--=%=%%##*-#
            +.#-%%*[email protected]:                   :+#*+++#*=--=----------=--=#*+++*#*-                   =%-#%#=+.*.
           .+:#-%%+-%@#                =#*++++++++*%#=#+======**+%%*++++++++*%=.              .%%%-*%#-#.*:
           :=-*-%%==*[email protected]+             -*=**********+=+*:+=....-*:#--+*********+-*=             *@=#-+%#-#:+-
           [email protected]@=++-##            :*-------------=*#*.=+=:.::*#*=-------------+*            #+-#[email protected]%-*-==
           =-#[email protected]@-#+--#           =%++++++++++++++%=+##:....:#*+=%++++++++++++++#*.          #--#[email protected]%-=+==
           +-#--%#-%@=-=*        =#*#--=+++++++++=-%=+*@%++++#@#++%--++++++++++--=##*.       [email protected]*-##--#-+
           *=*[email protected]@#--*:     :#*+#+--%+++++++++%-#=+*@%%%%%%@#++#-#*++++++++#+--#++#=     :*--%@%-----#-*
           #[email protected]@@*--*    +#+++#+-+#*++++++++%=#=+*@%%%%%%@#++*=+#+++++++***--#+++*#.   #--#@@@-----*=*
          .%*-----*@@@@+-+-  :#****##=-++++++++++==*--*%%%%%%%%#--*+-++++++++++==+%*****+  ++-*@@@@+----=**
           #%+----%@@@@#=-#    .... -+=+*@==*@@===%%#%%%%%%%%%%%%#%@*==%@#==%#++=# ..:..  .#-=#@@@@#----*%#
           %@@@%%@@@@@* *==+        +---#%[email protected]@..:%%%%%%%%%%%%%%%%%%+..#@#..*%---*.       #==* %@@@@@%@@@@#
           %@@@@@@@@@@:  *-#.       #[email protected]%[email protected]%[email protected]%%%%%%%%%%%%%%%%%*..*@#..*@+--+-      -*=*  [email protected]@@@@@@@@@%
           @%@@@@@@@@=   .*#:      .*--+%#[email protected]#[email protected]%%%%%%%%%%%%%%%%%#[email protected]#..+%#---+      =**    *@@@@@@@@#%
           %   .::.        .       -+--%%#::*@#:.+%%%%%%%%%%%%%%%%%%%.:[email protected]%::+%@---*       .       ..:..   %
           .                     -=+++++++======+%%%%%%%%%%%%%%%%%%%@*=======+++++*==.                    .
                               :*--+*#########*[email protected]%%%%%%%%%%%%%%%%%%--+#########**--*=
                              .*--#*++++++++++%[email protected]%%%%%%%%%%%%%%%%%%--#*+++++++++*#--++*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @author The Weirdos Team
/// @title SuperWeirdos NFT Contract
contract SuperWeirdos is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public constant MINT_PRICE_CLONES = 8;

    mapping(address => bool) public admins;
    bool public burningIsActive = false;
    bool public permanentBurnAddress = false;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public cloningAddress = 0xda216128024e122354BA20B648b8CC0a3E2Be51c;
    string public baseURI;
    string public contractURI;

    constructor() ERC721A("SuperWeirdos", "SW") {}

    /// @notice Caller is not a smart contract
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "Caller is contract");
        _;
    }

    /// @notice Sets the base URI for all tokens
    function setbaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Sets the contract URI for contract metadata
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice Adds an admin address permitted to airdrop
    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    /// @notice Sets the burn address for burning tokens
    /// @dev _permanentBurnAddress will prevent the burn address from being changed
    function setBurnAddress(address _burnAddress, bool _permanentBurnAddress)
        external
        onlyOwner
    {
        permanentBurnAddress = _permanentBurnAddress;
        burnAddress = _burnAddress;
    }

    /// @notice Activates burning
    /// @dev burningIsActive state is ignored by airdrops
    function setBurningIsActive(bool _burningIsActive) external onlyOwner {
        burningIsActive = _burningIsActive;
    }

    /// @notice Contract URI for contract metadata
    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    /// @notice URI for token metadata
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /// @notice Mints a token by burning a number of tokens defined by MINT_PRICE_CLONES
    function burnMint(uint256[MINT_PRICE_CLONES] memory _tokenIds)
        public
        nonReentrant
    {
        require(burningIsActive, "Burning is not active");
        require(totalSupply() < MAX_SUPPLY, "Burn would exceed max supply");
        for (uint256 i = 0; i < MINT_PRICE_CLONES; i++) {
            IERC721(cloningAddress).safeTransferFrom(
                msg.sender,
                burnAddress,
                _tokenIds[i]
            );
        }
        _safeMint(_msgSender(), 1);
    }

    /// @notice Mints a token at no cost to the caller (for airdrops)
    function airdropMint(address _recepient) public {
        require(totalSupply() < MAX_SUPPLY, "Airdrop would exceed max supply");
        require(admins[msg.sender], "Caller is not an admin");
        _safeMint(_recepient, 1);
    }

    /// @notice Convinience function for airdropping multiple tokens
    function massAirdropMint(address[] memory _recepient) public {
        require(
            totalSupply() + _recepient.length < MAX_SUPPLY + 1,
            "Airdrop would exceed max supply"
        );
        require(admins[msg.sender], "Caller is not an admin");
        for (uint256 i = 0; i < _recepient.length; i++) {
            _safeMint(_recepient[i], 1);
        }
    }
}