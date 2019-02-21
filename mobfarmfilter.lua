local recycleList = {
	"fiery",
	"superium",
	"inferium",
	"intermedium",
	"faraday",
	"boron",
	"manasteel",
	"iron",
	"golden_",
	"steeleaf"
}

local trashList = {
	"leather_",
	"manaweave",
	"tconstruct",
	"bow",
	"chain"
}

function drainAndInspect()
	turtle.select(1);
	local didSuck = turtle.suck(64);

	if didSuck == false then
		return false;
	end
	
	local data = turtle.getItemDetail(1);
	local name = data.name;
	return name;
end

function isRecycleable(name)
	local found;
	
	for i=1,#trashList do
		found = string.find( name, trashList[i]);

		if found then
			return "trash";
		end
	end

	for i=1,#recycleList do
		found = string.find( name, recycleList[i]);

		if found then
			return "recycle";
		end
	end
	
	return "default"
end

function drop( fn )
	local hasDropped = fn(64);
	if (hasDropped == false) then
		print("Please empty the fucking chest");

		while fn(64) == false do
			os.sleep(1);
		end
	end
end

while true do 
	local itemName = drainAndInspect();

	if itemName == false then
		os.sleep(1)
	else
		print(itemName);
		local canRecycle = isRecycleable(itemName);

		if canRecycle == "default" then
			print("storing");
			drop(turtle.dropUp);
		elseif canRecycle == "recycle" then
			print("recycling");
			drop(turtle.dropDown);
		else
			print("trashing");
			turtle.turnLeft();
			drop(turtle.drop);
			turtle.turnRight();
		end
	end
end
