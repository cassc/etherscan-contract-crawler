// SPDX-License-Identifier: GPL-3.0

/**
          _____                   _______                   _____                    _____                   _______                   _____          
         /\    \                 /::\    \                 /\    \                  /\    \                 /::\    \                 /\    \         
        /::\    \               /::::\    \               /::\    \                /::\    \               /::::\    \               /::\    \        
       /::::\    \             /::::::\    \             /::::\    \              /::::\    \             /::::::\    \             /::::\    \       
      /::::::\    \           /::::::::\    \           /::::::\    \            /::::::\    \           /::::::::\    \           /::::::\    \      
     /:::/\:::\    \         /:::/~~\:::\    \         /:::/\:::\    \          /:::/\:::\    \         /:::/~~\:::\    \         /:::/\:::\    \     
    /:::/  \:::\    \       /:::/    \:::\    \       /:::/  \:::\    \        /:::/  \:::\    \       /:::/    \:::\    \       /:::/__\:::\    \    
   /:::/    \:::\    \     /:::/    / \:::\    \     /:::/    \:::\    \      /:::/    \:::\    \     /:::/    / \:::\    \      \:::\   \:::\    \   
  /:::/    / \:::\    \   /:::/____/   \:::\____\   /:::/    / \:::\    \    /:::/    / \:::\    \   /:::/____/   \:::\____\   ___\:::\   \:::\    \  
 /:::/    /   \:::\ ___\ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /:::/    /   \:::\ ___\ |:::|    |     |:::|    | /\   \:::\   \:::\    \ 
/:::/____/     \:::|    ||:::|____|     |:::|    |/:::/____/  ___\:::|    |/:::/____/  ___\:::|    ||:::|____|     |:::|    |/::\   \:::\   \:::\____\
\:::\    \     /:::|____| \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\    \ /\  /:::|____| \:::\    \   /:::/    / \:::\   \:::\   \::/    /
 \:::\    \   /:::/    /   \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\    /::\ \::/    /   \:::\    \ /:::/    /   \:::\   \:::\   \/____/ 
  \:::\    \ /:::/    /     \:::\    /:::/    /     \:::\   \:::\ \/____/    \:::\   \:::\ \/____/     \:::\    /:::/    /     \:::\   \:::\    \     
   \:::\    /:::/    /       \:::\__/:::/    /       \:::\   \:::\____\       \:::\   \:::\____\        \:::\__/:::/    /       \:::\   \:::\____\    
    \:::\  /:::/    /         \::::::::/    /         \:::\  /:::/    /        \:::\  /:::/    /         \::::::::/    /         \:::\  /:::/    /    
     \:::\/:::/    /           \::::::/    /           \:::\/:::/    /          \:::\/:::/    /           \::::::/    /           \:::\/:::/    /     
      \::::::/    /             \::::/    /             \::::::/    /            \::::::/    /             \::::/    /             \::::::/    /      
       \::::/    /               \::/____/               \::::/    /              \::::/    /               \::/____/               \::::/    /       
        \::/____/                 ~~                      \::/____/                \::/____/                 ~~                      \::/    /        
         ~~                                                                                                                           \/____/         

                                                                                                                                    (for $DOG Owners)
    Author: Matt Condon (@1ofthemanymatts / @shrugs)
    Concept: This is basically just a conceptual art PFP, interrogating whether or not visuals are required to represent an identity,
             highlighting the power of 🌈 Imagination 🌈.
             
             Also it's just a fun Loot Project extension. There are 6969 Doggos.
             
             In Doge We Trust.
             
    Usage: Call adopt()
           
           msg.sender must own any number of $DOG
           msg.sender must not have adopted a Doggo before
            
 */

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Doggos is ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    IERC20 public token;
    mapping(address => bool) private claimed;
    uint256 constant MAX_SUPPLY = 6969;

    string[] private species = [
        "Shiba Inu","Bulldog","Dalmatian","Golden Retriever","Shih Tzu","Burnese Mountain Dog","Border Collie","Chow Chow","Bichon Frise","Miniature Schnauzer",
        "Pomeranian ","Malteese","Golden Doodle","Dachshund","Yorkshire Terrier","Corgi","German Shepherd","Labrador","Beagle","Chihuahua","Great Dane","Greyhound",
        "Frenchie","Ugly Pug","American Eskimo Dog","Husky"
    ];
    
    string[] private abilities = [
        "Knows a Friend Who Knows a Friend","Strong Vibes","Maximum Comf","Zoomies","Chillaxing","Hibernation","Luxurious Stretching","Does Yoga With You",
        "Can Lift Any Stick","Diamond Paws","Digs the Biggest Holes","Furious Tail Wags","Paddles Vigorously","Cute Bork","Powerful Bork","100k Instagram Followers",
        "Incredibly Boopable Snoot","A Great Heckin Smile","Has a PhD","Shakes Every Hand","Famous on Crypto Twitter","Has Elon Musk on Speed Dial","Types at 200wpm",
        "14/10 Very Good Doggo","Always Smells Really Good","Is Shl0ms","Posts 'gm' Every Morning","Posts 'gn' Every Night","Accredited Investor","Expert Meme Maker",
        "Wears Unisocks","Uses a Split Mechanical Keyboard","Runs Next To You","Can Fit In a Bike Basket","Achieves Mission Impawsible","Never Barks Up the Wrong Tree",
        "Never Has a Ruff Day","Tailed by Pup-arazzi","On the Cover of Vanity Fur","The Pug Life Chose Them"
    ];
    
    string[] private chests = [
        "Comfy Robe","Petticoat","Dapper Vest","Tank Top","Spaghetti Strap","Plain White T","Muscle Tee","Crop Top","Cute lil Bowtie","Off the Shoulder Top",
        "The Joy Division Tee","An Adorable Skirt","Mechanic's Coveralls","Fur Coat","Overalls","Tuxedo","Camoflauge","Wedding Dress","Sailor Outfit","Ballerina Tutu",
        "Rainbow Leash ","Magical Cape","Doggy Cape","Crop Top","Luxurious Fur","Bikini Top","Canadian Tuxedo","Mini Skirt","Ripped Denim Jacket","PleasrDAO Box Logo T"
    ];
    
    string[] private heads = [
        "Pirate Hat","Fedora","Dad Hat","Sherlock Hat","Cowboy Hat","Newsie","Bandana ","Sweatband","Tennis Visor","Mariner's Cap","Durag","Ascot","Scarf","Hipster 5-Panel",
        "Bike Cap","Bucket Hat","Beanie Hat","Top Hat","Sunglasses","Fake Mustache","Smoking Pipe","Crown","Tiara","Flower Crown","Monocle","Sun Hat","Christmas Hat","Ribbon",
        "Cat Ears","Bunny Ears","Swim Cap"
    ];
    
    string[] private namePrefixes = [
        "Ser","Chef","Boss","Count","Maestro","Captain","Major","Colonel","Their Excellency","Professor","Chancellor","Vice Chancellor","Principal","President",
        "Chief Executive","Secretary ","Janitor ","Teacher","DJ","Baby","Commissioner","The One and Only","Giga Chad","Seed Investor ","Head Engineer","Intern",
        "Acting President","Comrade","The Very Wow","Park Ranger","Pope","Ranking Official","DAO Council Member","Multisig Signer"
    ];
    
    string[] private names = [
        "Sushi","Dumpling","Genevive","Pancake","Yuki","Gigi","Happy","Chibi","Lucky","Mochi","Bubba","Yui","Matcha","Jerry","Bunny","Candy","Bubbles","Apricot",
        "Bear","Button","Freckles","Noodle","Muffin","Sprout","Peachy","Wafflestiltskin","Peanut","Teddy","Pebbles","Kabochan","Tadeo","Abby","Abe","Addie","Ace",
        "Alexis","Aero","Alice","Aiden","Amelia","AJ","Angel","Alfie","Annie","Andy","Ariel","Archie","Ava","Artie","Avery","Atlas","Baby","Austin","Bailey","Bailey",
        "Bambi","Baja","Basil","Barkley","Bea","Basil","Bean","Baxter","Bella","Bean","Belle","Bear","Betty","Beau","Birdie","Benji","Biscuit","Benny","Blanche","Billy",
        "Blondie","Bingo","Blossom","Biscuit","Bonnie","Blaze","Brooklyn","Blue","Buffy","Bo","Callie","Bolt","Candy","Boomer","Carly","Boots","Carmen","Brady","Casey",
        "Brownie","Cece","Bubba","Chance","Buck","Chanel","Buddy","Cherry","Buster","Cheyenne","Buttons","Chloe","Buzz","Cinnamon","Cain","Clara","Captain","Cleo","Carter",
        "Clover","Champ","Coco","Chance","Cookie","Charlie","Cora","Chase","Cricket","Chester","Daisy","Chewy","Dakota","Chico","Dallas","Chip","Daphne","CJ","Darla","Clifford",
        "Delia","Clyde","Delilah","Cody","Destiny","Cooper","Diamond","Corky","Diva","Cosmo","Dixie","Darwin","Dolly","Dash","Dora","Davy","Dory","Denver","Dot","Dexter","Dottie",
        "Diesel","Duchess","Dijon","Eden","Donnie","Edie","Dudley","Effie","Duffy","Eliza","Duke","Ella","Dusty","Ellie","Dylan","Eloise","Eddie","Elsa","Eli","Ember",
        "Eliot","Emma","Elton","Emmy","Everett","Etta","Ezra","Eva","Farley","Faith","Felix","Fancy","Finley","Fannie","Finn","Fanny","Fisher","Faye","Flash","Fifi",
        "Forrest","Flo","Frank","Foxy","Frankie","Frida","Franklin","Gabby","Freddy","Georgia","Fritz","Gia","Gage","Gidget","George","Gigi","Ghost","Ginger","Goose",
        "Gloria","Gordy","Goldie","Grady","Grace","Gus","Gracie","Harley","Hadley","Harry","Hailey","Harvey","Hannah","Hayes","Harley","Henry","Harper","Hooch","Hazel",
        "Hoss","Heidi","Huck","Hershey","Hudson","Holly","Hunter","Honey","Ike","Hope","Indy","Ibby","Ira","Ida","Jack","Iris","Jackson","Ivory","Jasper","Ivy","Java",
        "Izzy","Jesse","Jackie","Jethro","Jada","Joey","Jade","Jordan","Jasmine","Jordy","Jazzy","Kane","Jenna","King","Jersey","Knox","Jewel","Koby","Jolene","Koda",
        "Josie","Lance","Juno","Lenny","Karma","Leo","Kayla","Leroy","Kennedy","Levi","Kiki","Lewis","Kinley","Lightning","Kira","Lincoln","Kiwi","Linus","Koda",
        "Logan","Koko","Loki","Lacy","Louie","Lady","Lyle","Laika","Mac","Lassie","Major","Layla","Marley","Leia","Marty","Lena","Mason","Lexi","Max","Lexy",
        "Maximus","Libby","Maxwell","Liberty","Mickey","Lilly","Miles","Lola","Milo","Lottie","Moe","Lucky","Monty","Lucy","Morty","Lulu","Murphy","Luna",
        "Murray","Mabel","Nelson","Macy","Newton","Maddie","Nico","Maisie","Niles","Mavis","Noah","Maya","Norm","Mia","Oakley","Miley","Odin","Millie","Ollie",
        "Mimi","Orson","Minnie","Oscar","Missy","Otis","Mocha","Otto","Molly","Ozzy","Morgan","Paco","Moxie","Pal","Muffin","Parka","Nala","Parker","Nellie","Patch",
        "Nessie","Peanut","Nettie","Pepper","Nikki","Percy","Nola","Perry","Nori","Petey","Odessa","Pip","Olive","Piper","Olivia","Poe","Opal","Pogo","Oreo","Pongo",
        "Paige","Porter","Paris","Prince","Parker","Quincy","Peaches","Randy","Peanut","Ranger","Pearl","Rascal","Pebbles","Red","Peggy","Reggie","Penny","Ricky",
        "Pepper","Ringo","Petra","Ripley","Phoenix","Rocky","Piper","Rudy","Pippa","Rufus","Pixie","Rusty","Polly","Sam","Poppy","Sammy","Precious","Sarge","Princess",
        "Sawyer","Pumpkin","Scooby","Queenie","Scooter","Remy","Scout","Riley","Scrappy","Rosie","Shadow","Roxy","Shiloh","Ruby","Simba","Ruthie","Skip","Sadie","Smoky",
        "Sandy","Snoopy","Sasha","Socks","Sassy","Sparky","Scarlet","Spencer","Shadow","Spike","Sheba","Spot","Shelby","Stanley","Shiloh","Stewie","Sierra","Stitch",
        "Sissy","Taco","Skye","Tank","Skylar","Tanner","Sophie","Taylor","Star","Taz","Starla","Teddy","Stella","Titus","Storm","TJ","Sugar","Tobias","Suki","Toby",
        "Summer","Tot","Sunny","Toto","Suzie","Tripp","Sweetie","Tucker","Sydney","Turbo","Tabby","Turner","Taffy","Tyler","Tasha","Tyson","Tessa","Vernon","Theo",
        "Vince","Tilly","Vinnie","Trixie","Wade","Trudy","Waffles","Violet","Wally","Vixen","Walter","Wiggles","Watson","Willa","Wilbur","Willow","Winston","Winnie",
        "Woody","Xena","Wyatt","Zelda","Wylie","Zoe","Yogi","Zola","Zane","Zuri","Ziggy"
    ];
    
    string[] private nameSuffixes = [
        "First of Their Name","the Second","the Third","the Fourth","the Coolest","Esq.","Jr.","\u69d8","Sr.","the One and Only","the Right Honorable",
        "PhD","Dr.","et al.","the Most Honorable","the Honorable","Pleasr of Ppl","CPA","JD","MBA","MD","JD/MBA"
    ];
    
    string[] private suffixes = [
        "of Cuteness","of Pamp","of Comfy","of Yields","of Sniffles","of Cuddles","of Flowers","of Love","of Passion","of Enthusiasm",
        "of Hope","of Optimism","of Crypto Power","of Crypto Trading","of NFT Flipping","of Memes","of The Doge Foundation","of Delight",
        "of Pleasing","of Pleasure","of Joy"
    ];
    
    function random(string memory keyPrefix, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(keyPrefix, Strings.toString(tokenId))));
    }
    
    function getName(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random("NAMES", tokenId);
        string memory output = names[rand % names.length];
        uint256 odds = rand % 3;
        
        if (odds > 0) {
            // prefix
            output = string(abi.encodePacked(namePrefixes[rand % namePrefixes.length], ' ', output));
            
            if (odds > 1) {
                // suffix
                output = string(abi.encodePacked(output, ' ', nameSuffixes[rand % nameSuffixes.length]));
            }
        }
        
        return output;
    }
    
    function getSpecies(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SPECIES", species, true);
    }
    
    function getAbility(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABILITY", abilities, false);
    }
    
    function getChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CHEST", chests, true);
    }
    
    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD", heads, true);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray, bool hasSuffix) internal view returns (string memory) {
        uint256 rand = random(keyPrefix, tokenId);
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        
        if (hasSuffix && greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        
        return output;
    }
    

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getName(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getSpecies(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getAbility(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getChest(tokenId);
        
        parts[8] = '</text><text x="10" y="100" class="base">';
        
        parts[9] = getHead(tokenId);

        parts[10] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', getName(tokenId) ,' (Doggo #', Strings.toString(tokenId), ')", "description": "Doggos for stewards of The Doge NFT. Feel free to use Doggos in any way you want. In Doge We Trust.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function adopt() public nonReentrant {
        require(token.balanceOf(_msgSender()) > 0, "Must own $DOG to adopt a doggo.");
        require(!claimed[_msgSender()], "One doggo per owner, pls.");
        require(totalSupply() <= MAX_SUPPLY, "Too many dogs in the house!");
        
        claimed[_msgSender()] = true;
        
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(_msgSender(), tokenId);
    }
    
    constructor(IERC20 _token) ERC721("Doggos (for DOG Owners)", "DOGGO") {
        token = _token;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}