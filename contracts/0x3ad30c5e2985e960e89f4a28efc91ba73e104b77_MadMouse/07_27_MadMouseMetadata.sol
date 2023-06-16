//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import './Gouda.sol';
import './MadMouse.sol';
import './MadMouseStaking.sol';
import './lib/Base64.sol';
import './lib/MetadataEncode.sol';
import './lib/Ownable.sol';

contract MadMouseMetadata is Ownable {
    using Strings for uint256;
    using MetadataEncode for bytes;
    using TokenDataOps for uint256;
    using DNAOps for uint256;

    struct Mouse {
        string role;
        string rarity;
        string fur;
        string expression;
        string glasses;
        string hat;
        string body;
        string background;
        string makeup;
        string scene;
    }

    uint256 constant CLOWN = 0;
    uint256 constant MAGICIAN = 1;
    uint256 constant JUGGLER = 2;
    uint256 constant TRAINER = 3;
    uint256 constant PERFORMER = 4;

    /* ------------- Traits ------------- */

    // ["Clown", "Magician", "Juggler", "Trainer", "Performer"]
    bytes constant ROLE = hex'436c6f776e004d6167696369616e004a7567676c657200547261696e657200506572666f726d6572';

    // ["Common", "Rare", "Super", "Ultra"]
    bytes constant RARITIES = hex'436f6d6d6f6e005261726500537570657200556c747261';

    // ["Ghost", "Gold", "Lava", "Panther", "Camo", "Blue-Pink", "White", "Pink", "Brown", "Dark Brown", "Green", "Grey", "Ice", "Purple", "Red"]
    bytes constant FUR =
        hex'47686f737400476f6c64004c6176610050616e746865720043616d6f00426c75652d50696e6b0057686974650050696e6b0042726f776e004461726b2042726f776e00477265656e00477265790049636500507572706c6500526564';

    // ["Awkward", "Angry", "Bored", "Confused", "Grimaced", "Loving", "Laughing", "Sad", "Shy", "Stupid", "Whistling"]
    bytes constant EXPRESSION =
        hex'41776b7761726400416e67727900426f72656400436f6e6675736564004772696d61636564004c6f76696e67004c61756768696e670053616400536879005374757069640057686973746c696e67';

    // ["Purple", "Green", "Blue", "Light Blue", "Red", "Yellow", "Light Green", "Pink", "Orange", "Throne", "Star Ring", "Colosseum"]
    bytes constant BACKGROUND =
        hex'507572706c6500477265656e00426c7565004c6967687420426c7565005265640059656c6c6f77004c6967687420477265656e0050696e6b004f72616e6765005468726f6e6500537461722052696e6700436f6c6f737365756d';

    // ["Black", "White", "Blue", "Kimono", "Toge", "Cowboy", "Guard", "Farmer", "Napoleon", "King", "Jumper", "Sailor", "Pirate", "Mexican", "Robin Hood", "Elf", "Viking", "Vampire", "Crocodile", "Asian", "Showman", "Genie", "Barong"]
    bytes constant BODY =
        hex'426c61636b00576869746500426c7565004b696d6f6e6f00546f676500436f77626f79004775617264004661726d6572004e61706f6c656f6e004b696e67004a756d706572005361696c6f7200506972617465004d65786963616e00526f62696e20486f6f6400456c660056696b696e670056616d706972650043726f636f64696c6500417369616e0053686f776d616e0047656e6965004261726f6e67';

    // ["None", "Black", "White", "Jester", "Sakat", "Laurel", "Cowboy", "Guard", "Farmer", "Napoleon", "Crown", "Helicopter", "Sailor", "Pirate", "Mexican", "Robin Hood", "Elf", "Viking", "Halo", "Crocodile", "Asian", "Showman", "Genie", "Salakot"]
    bytes constant HAT =
        hex'4e6f6e6500426c61636b005768697465004a65737465720053616b6174004c617572656c00436f77626f79004775617264004661726d6572004e61706f6c656f6e0043726f776e0048656c69636f70746572005361696c6f7200506972617465004d65786963616e00526f62696e20486f6f6400456c660056696b696e670048616c6f0043726f636f64696c6500417369616e0053686f776d616e0047656e69650053616c616b6f74';

    // ["None", "Red", "Green", "Yellow", "Vyper", "Thief", "Cyber", "Rainbow", "3D", "Thug", "Gold", "Monocle", "Manga", "Black", "Ray Black", "Blue", "Purple", "Cat Mask"]
    bytes constant GLASSES =
        hex'4e6f6e650052656400477265656e0059656c6c6f77005679706572005468696566004379626572005261696e626f77003344005468756700476f6c64004d6f6e6f636c65004d616e676100426c61636b0052617920426c61636b00426c756500507572706c6500436174204d61736b';

    // ["Clown 1", "Clown 2", "Clown 3", "Clown 4", "Clown 5", "Clown 6", "Clown 7", "Clown 8", "Clown 9"]
    bytes constant CLOWN_MAKEUP =
        hex'436c6f776e203100436c6f776e203200436c6f776e203300436c6f776e203400436c6f776e203500436c6f776e203600436c6f776e203700436c6f776e203800436c6f776e2039';

    // ["Pie", "Balloons", "Twisted Balloons", "Jack in the Box", "Water Spray", "Puppets", "String", "Little Pierre", "Little Murphy"]
    bytes constant CLOWN_BODY_LEVEL_2 =
        hex'5069650042616c6c6f6f6e7300547769737465642042616c6c6f6f6e73004a61636b20696e2074686520426f78005761746572205370726179005075707065747300537472696e67004c6974746c6520506965727265004c6974746c65204d7572706879';

    // ["Purple Wig", "Rainbow Wig", "Blue Wig", "Teal Wig", "Red Wig", "Green Wig", "Harlequin", "Black Beret", "Blue Beret"]
    bytes constant CLOWN_WIG_LEVEL_2 =
        hex'507572706c6520576967005261696e626f772057696700426c756520576967005465616c20576967005265642057696700477265656e20576967004861726c657175696e00426c61636b20426572657400426c7565204265726574';

    // ["Pie Master", "Balloon Master", "Twisted Balloon Master", "Jack in the Box Master", "Rainbow Flow", "Puppet Master", "String Master", "Pierre", "Murphy"]
    bytes constant CLOWN_BODY_LEVEL_3 =
        hex'506965204d61737465720042616c6c6f6f6e204d617374657200547769737465642042616c6c6f6f6e204d6173746572004a61636b20696e2074686520426f78204d6173746572005261696e626f7720466c6f7700507570706574204d617374657200537472696e67204d617374657200506965727265004d7572706879';

    // ["Blue Poster", "Up!", "Red Poster", "Dance Floor", "Red Curtains", "Puppets", "Stadium", "Paris", "New York"]
    bytes constant CLOWN_BACKGROUND_LEVEL_3 =
        hex'426c756520506f73746572005570210052656420506f737465720044616e636520466c6f6f7200526564204375727461696e730050757070657473005374616469756d005061726973004e657720596f726b';

    // ["Hatter", "Card", "Wizard", "Pento", "Fortune", "Fantasy", "Majestic", "Prisoner"]
    bytes constant MAGICIAN_HAT =
        hex'48617474657200436172640057697a6172640050656e746f00466f7274756e650046616e74617379004d616a657374696300507269736f6e6572';

    // ["Doves", "Cards", "Wand", "Rabbit", "Crystal", "Levitation", "Saw", "Handcuffed"]
    bytes constant MAGICIAN_BODY_LEVEL_2 =
        hex'446f7665730043617264730057616e6400526162626974004372797374616c004c657669746174696f6e005361770048616e64637566666564';

    // ["Phoenix", "Card Master", "Wand Master", "Rainbow", "Snow Globe", "Levitation Master", "Grater", "Cement"]
    bytes constant MAGICIAN_BODY_LEVEL_3 =
        hex'50686f656e69780043617264204d61737465720057616e64204d6173746572005261696e626f7700536e6f7720476c6f6265004c657669746174696f6e204d6173746572004772617465720043656d656e74';

    // ["Blue Curtains", "Pink Poster", "Sky", "Hills", "Snow", "Space", "Factory", "Construction Site"]
    bytes constant MAGICIAN_BACKGROUND_LEVEL_3 =
        hex'426c7565204375727461696e730050696e6b20506f7374657200536b790048696c6c7300536e6f7700537061636500466163746f727900436f6e737472756374696f6e2053697465';

    // ["None", "Fairy Mouse", "Flying Key", "Owl", "Flying Pot", "Little Mouse", "Light Aura", "Book"]
    bytes constant MAGICIAN_SCENE_LEVEL_3 =
        hex'4e6f6e65004661697279204d6f75736500466c79696e67204b6579004f776c00466c79696e6720506f74004c6974746c65204d6f757365004c69676874204175726100426f6f6b';

    // ["Juggling Balls", "Clubs", "Knives", "Hoops", "Spinning Plate", "Bolas", "Diabolo", "Slinky"]
    bytes constant JUGGLER_BODY =
        hex'4a7567676c696e672042616c6c7300436c756273004b6e6976657300486f6f7073005370696e6e696e6720506c61746500426f6c617300446961626f6c6f00536c696e6b79';

    // ["Juggling Ball Scholar", "Club Scholar", "Knife Scholar", "Hoop Scholar", "Spinning Plate Scholar", "Bolas Scholar", "Diabolo Scholar", "Slinky Scholar"]
    bytes constant JUGGLER_BODY_LEVEL_2 =
        hex'4a7567676c696e672042616c6c205363686f6c617200436c7562205363686f6c6172004b6e696665205363686f6c617200486f6f70205363686f6c6172005370696e6e696e6720506c617465205363686f6c617200426f6c6173205363686f6c617200446961626f6c6f205363686f6c617200536c696e6b79205363686f6c6172';

    // ["Juggling Ball Master", "Club Master", "Knife Master", "Hoop Master", "Spinning Plate Master", "Bolas Master", "Diabolo Master", "Slinky Master"]
    bytes constant JUGGLER_BODY_LEVEL_3 =
        hex'4a7567676c696e672042616c6c204d617374657200436c7562204d6173746572004b6e696665204d617374657200486f6f70204d6173746572005370696e6e696e6720506c617465204d617374657200426f6c6173204d617374657200446961626f6c6f204d617374657200536c696e6b79204d6173746572';

    // ["Spotlight Top", "Manor", "Target", "Forest", "Spotlight Green-Pink", "Desert", "Fireworks", "Shadow"]
    bytes constant JUGGLER_BACKGROUND_LEVEL_3 =
        hex'53706f746c6967687420546f70004d616e6f720054617267657400466f726573740053706f746c6967687420477265656e2d50696e6b004465736572740046697265776f726b7300536861646f77';

    // ["Gecko", "Cat", "Chimp", "Turtle", "Donkey", "Teddy Bear", "Seal", "Baby Dodo"]
    bytes constant TRAINER_PET =
        hex'4765636b6f00436174004368696d7000547572746c6500446f6e6b65790054656464792042656172005365616c004261627920446f646f';

    // ["Blue Whip", "Red Hoop", "Banana", "Green Whip", "Horse Whip", "Honey", "Fish", "Blue Hoop"]
    bytes constant TRAINER_BODY_LEVEL_2 =
        hex'426c756520576869700052656420486f6f700042616e616e6100477265656e205768697000486f727365205768697000486f6e6579004669736800426c756520486f6f70';

    // ["Crocodile", "Tiger", "Monkey", "Komodo", "Horse", "Bear", "Otaria", "Dodo"]
    bytes constant TRAINER_PET_LEVEL_2 =
        hex'43726f636f64696c65005469676572004d6f6e6b6579004b6f6d6f646f00486f7273650042656172004f746172696100446f646f';

    // ["Light Whip", "Fire Hoop", "Bananas", "Rainbow Whip", "Uniwhip", "Bamboo", "Fish Feast", "Rainbow Hoop"]
    bytes constant TRAINER_BODY_LEVEL_3 =
        hex'4c696768742057686970004669726520486f6f700042616e616e6173005261696e626f77205768697000556e69776869700042616d626f6f0046697368204665617374005261696e626f7720486f6f70';

    // ["T-Rex", "Lion", "Gorilla", "Dragon", "Unicorn", "Panda", "Walrus", "Peacock"]
    bytes constant TRAINER_PET_LEVEL_3 =
        hex'542d526578004c696f6e00476f72696c6c6100447261676f6e00556e69636f726e0050616e64610057616c72757300506561636f636b';

    // ["Tent", "Red Ring", "Green Ring", "Castle", "Lake", "Bamboo", "Grey Ring", "Peacock"]
    bytes constant TRAINER_BACKGROUND_LEVEL_3 =
        hex'54656e74005265642052696e6700477265656e2052696e6700436173746c65004c616b650042616d626f6f00477265792052696e6700506561636f636b';

    // ["Hula Hoop", "Rolla Bolla", "Monocycle", "Aerial Hoop", "None", "Swing", "Dumbbells", "Trampoline"]
    bytes constant PERFORMER_SCENE =
        hex'48756c6120486f6f7000526f6c6c6120426f6c6c61004d6f6e6f6379636c650041657269616c20486f6f70004e6f6e65005377696e670044756d6262656c6c73005472616d706f6c696e65';

    // ["Trickster", "Rolla Bolla", "Funambulist", "Trapezist", "Pendulum Master", "Dancer", "Mr Muscle", "Trampoline"]
    bytes constant PERFORMER_BODY_LEVEL_2 =
        hex'547269636b7374657200526f6c6c6120426f6c6c610046756e616d62756c6973740054726170657a6973740050656e64756c756d204d61737465720044616e636572004d72204d7573636c65005472616d706f6c696e65';

    // ["Hula Hoop Trickster", "Tower", "Funambulist", "Trapezist Twins", "None", "Tap Dance", "Dumbbell Stand", "Cody"]
    bytes constant PERFORMER_SCENE_LEVEL_2 =
        hex'48756c6120486f6f7020547269636b7374657200546f7765720046756e616d62756c6973740054726170657a697374205477696e73004e6f6e65005461702044616e63650044756d6262656c6c205374616e6400436f6479';

    // ["Chairman", "Skater", "Daredevil", "Megaphone", "None", "Virtuoso", "Hercules", "Canonist"]
    bytes constant PERFORMER_BODY_LEVEL_3 =
        hex'43686169726d616e00536b617465720044617265646576696c004d65676170686f6e65004e6f6e650056697274756f736f0048657263756c65730043616e6f6e697374';

    // ["Pyramid", "Skater", "Daredevil", "Firestar", "None", "Salsa", "Barbell", "Canonman"]
    bytes constant PERFORMER_SCENE_LEVEL_3 =
        hex'507972616d696400536b617465720044617265646576696c004669726573746172004e6f6e650053616c73610042617262656c6c0043616e6f6e6d616e';

    // ["Red Podium", "Half-Pipe", "Blue Podium", "Dark Tent", "Mesmerized", "Stage", "Hercules Poster", "Purple Ring"]
    bytes constant PERFORMER_BACKGROUND_LEVEL_3 =
        hex'52656420506f6469756d0048616c662d5069706500426c756520506f6469756d004461726b2054656e74004d65736d6572697a65640053746167650048657263756c657320506f7374657200507572706c652052696e67';

    /* ------------- Rarities ------------- */

    // [9, 9, 14, 14, 14, 14, 17, 18, 21, 21, 21, 21, 21, 21, 21]
    uint256 constant WEIGHTS_FUR = 0x00000000000000000000000000000000001515151515151512110e0e0e0e0909;

    // [63, 14, 14, 14, 5, 14, 5, 5, 14, 14, 14, 14, 5, 14, 14, 14, 14, 5]
    uint256 constant WEIGHTS_GLASSES = 0x0000000000000000000000000000050e0e0e0e050e0e0e0e05050e050e0e0e3f;

    // [8, 8, 8, 15, 15, 15, 15, 15, 8, 2, 15, 15, 15, 15, 15, 15, 3, 3, 3, 15, 3, 15, 15]
    uint256 constant WEIGHTS_BODY = 0x0000000000000000000f0f030f0303030f0f0f0f0f0f02080f0f0f0f0f080808;

    // [25, 25, 25, 25, 25, 25, 25, 25, 25, 10, 11, 10]
    uint256 constant WEIGHTS_BACKGROUND = 0x00000000000000000000000000000000000000000a0b0a191919191919191919;

    // [13, 8, 8, 8, 14, 14, 14, 14, 14, 8, 3, 14, 14, 14, 14, 14, 14, 3, 3, 3, 14, 3, 14, 14]
    uint256 constant WEIGHTS_HAT = 0x00000000000000000e0e030e0303030e0e0e0e0e0e03080e0e0e0e0e0808080d;

    /* ------------- External ------------- */

    MadMouse public madmouse;

    function setMadMouseAddress(MadMouse madmouse_) external onlyOwner {
        madmouse = madmouse_;
    }

    // will act as an ERC721 proxy
    function balanceOf(address user) external view returns (uint256) {
        return madmouse.numOwned(user);
    }

    function buildMouseMetadata(uint256 tokenId, uint256 level) external view returns (string memory) {
        return string.concat('data:application/json;base64,', Base64.encode(bytes(mouseMetadataJSON(tokenId, level))));
    }

    /* ------------- Json ------------- */

    function getMouse(uint256 dna, uint256 level) private pure returns (Mouse memory mouse) {
        uint256 dnaRole = dna & 0xFF;
        uint256 dnaFur = (dna >> 8) & 0xFF;
        uint256 dnaClass = (dna >> 16) & 0xFF;
        uint256 dnaExpression = (dna >> 24) & 0xFF;
        uint256 dnaGlasses = (dna >> 32) & 0xFF;
        uint256 dnaBody = (dna >> 40) & 0xFF;
        uint256 dnaBackground = (dna >> 48) & 0xFF;
        uint256 dnaHat = (dna >> 56) & 0xFF;
        uint256 dnaSpecial = (dna >> 64) & 0xFF;

        uint256 role = dnaRole % 5;

        mouse.role = ROLE.decode(role);
        mouse.rarity = RARITIES.decode(dna.toRarity());
        mouse.fur = FUR.selectWeighted(dnaFur, WEIGHTS_FUR);
        mouse.expression = EXPRESSION.decode(dnaExpression % 11);
        mouse.glasses = GLASSES.selectWeighted(dnaGlasses, WEIGHTS_GLASSES);
        mouse.body = BODY.selectWeighted(dnaBody, WEIGHTS_BODY);
        mouse.background = BACKGROUND.selectWeighted(dnaBackground, WEIGHTS_BACKGROUND);
        mouse.hat = HAT.selectWeighted(dnaHat, WEIGHTS_HAT);

        uint256 class;

        if (role == CLOWN) {
            class = dnaClass % 9;

            mouse.makeup = CLOWN_MAKEUP.decode(class);

            if (level == 2) mouse.body = CLOWN_BODY_LEVEL_2.decode(class);
            if (level >= 2) {
                uint256 hat = dnaHat % 9;
                if (hat == 6) hat = class;
                mouse.hat = CLOWN_WIG_LEVEL_2.decode(hat);
            }

            if (level == 3) mouse.body = CLOWN_BODY_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 9;
                if (backgroundType == 6) mouse.background = CLOWN_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = CLOWN_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == MAGICIAN) {
            class = dnaClass % 8;

            mouse.hat = MAGICIAN_HAT.decode(class);

            if (level == 2) mouse.body = MAGICIAN_BODY_LEVEL_2.decode(class);

            if (level == 3) mouse.body = MAGICIAN_BODY_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 sceneType = dnaSpecial % 8;
                if (class == 1 && (sceneType < 4 || 6 < sceneType)) sceneType = 4;
                mouse.scene = MAGICIAN_SCENE_LEVEL_3.decode(sceneType);
            }
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 6) mouse.background = MAGICIAN_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = MAGICIAN_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == JUGGLER) {
            class = dnaClass % 8;

            if (level == 1) mouse.body = JUGGLER_BODY.decode(class);

            if (level == 2) mouse.body = JUGGLER_BODY_LEVEL_2.decode(class);

            if (level == 3) mouse.body = JUGGLER_BODY_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 2) mouse.background = JUGGLER_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = JUGGLER_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == TRAINER) {
            class = dnaClass % 8;

            if (level == 1) mouse.scene = TRAINER_PET.decode(class);

            if (level == 2) mouse.body = TRAINER_BODY_LEVEL_2.decode(class);
            if (level == 2) mouse.scene = TRAINER_PET_LEVEL_2.decode(class);

            if (level == 3) mouse.body = TRAINER_BODY_LEVEL_3.decode(class);
            if (level == 3) mouse.scene = TRAINER_PET_LEVEL_3.decode(class);
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 7) mouse.background = TRAINER_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = TRAINER_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }

        if (role == PERFORMER) {
            class = dnaClass % 8;

            if (level >= 1) {
                if (class == 4) mouse.body = 'Hypnotist';
                else mouse.scene = PERFORMER_SCENE.decode(class);
            }

            if (level >= 2) mouse.body = PERFORMER_BODY_LEVEL_2.decode(class);
            if (level >= 2 && class != 4) mouse.scene = PERFORMER_SCENE_LEVEL_2.decode(class);

            if (level == 3) {
                if (class != 4) mouse.body = PERFORMER_BODY_LEVEL_3.decode(class);
                if (class != 4) mouse.scene = PERFORMER_SCENE_LEVEL_3.decode(class);
                if (class == 4) mouse.glasses = 'Hypnotist';
            }
            if (level == 3) {
                uint256 backgroundType = dnaBackground % 8;
                if (backgroundType == 1 || backgroundType == 4 || backgroundType == 5 || backgroundType == 6)
                    mouse.background = PERFORMER_BACKGROUND_LEVEL_3.decode(class);
                else mouse.background = PERFORMER_BACKGROUND_LEVEL_3.decode(backgroundType);
            }
        }
    }

    function mouseMetadataJSON(uint256 tokenId, uint256 level) private view returns (string memory) {
        uint256 dna = madmouse.getDNA(tokenId);

        bool mintAndStake = madmouse._tokenDataOf(tokenId).mintAndStake();

        string memory name = madmouse.mouseName(tokenId);
        string memory bio = madmouse.mouseBio(tokenId);

        if (bytes(name).length == 0) name = string.concat('Mad Mouse #', tokenId.toString());
        if (bytes(bio).length == 0) bio = madmouse.description();

        string memory imageURI = string.concat(
            madmouse.imagesBaseURI(),
            ((level - 1) * 10_000 + tokenId).toString(),
            '.png'
        );

        string memory baseData = string.concat(
            MetadataEncode.keyValueString('name', name),
            MetadataEncode.keyValueString('description', bio),
            MetadataEncode.keyValueString('image', imageURI),
            MetadataEncode.keyValue('id', tokenId.toString()),
            MetadataEncode.keyValueString('dna', dna.toHexString())
        );

        string memory result = string.concat(
            '{',
            baseData,
            MetadataEncode.keyValueString('OG', mintAndStake ? 'Staker' : ''),
            MetadataEncode.attributes(getAttributesList(dna, level)),
            '}'
        );

        return result;
    }

    function getAttributesList(uint256 dna, uint256 level) private pure returns (string memory) {
        Mouse memory mouse = getMouse(dna, level);

        string memory attributes = string.concat(
            MetadataEncode.attribute('Level', level.toString()),
            MetadataEncode.attributeString('Role', mouse.role),
            MetadataEncode.attributeString('Rarity', mouse.rarity),
            MetadataEncode.attributeString('Background', mouse.background),
            MetadataEncode.attributeString('Scene', mouse.scene),
            MetadataEncode.attributeString('Fur', mouse.fur)
        );

        attributes = string.concat(
            attributes,
            MetadataEncode.attributeString('Expression', mouse.expression),
            MetadataEncode.attributeString('Glasses', mouse.glasses),
            MetadataEncode.attributeString('Hat', mouse.hat),
            MetadataEncode.attributeString('Makeup', mouse.makeup),
            MetadataEncode.attributeString('Body', mouse.body, false)
        );

        return attributes;
    }

    // function getOGStatus(uint256 ownerCount) private pure returns (string memory) {
    //     return
    //         ownerCount == 1 ? MetadataEncode.keyValueString('OG', 'Minter') : ownerCount == 2
    //             ? MetadataEncode.keyValueString('OG', 'Hodler')
    //             : '';
    // }

    // function getHodlerStatus(uint256 timestamp) private view returns (string memory) {
    //     return
    //         (block.timestamp - timestamp) > 69 days
    //             ? MetadataEncode.keyValueString('HODLER LEVEL', 'Diamond Handed')
    //             : '';
    // }
}