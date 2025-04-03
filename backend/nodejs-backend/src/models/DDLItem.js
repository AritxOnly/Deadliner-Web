class DDLItem {
    constructor({
        id = -1,
        name,
        startTime,
        endTime,
        isCompleted = false,
        completeTime = "",
        note,
        isArchived = false,
        isStared = false,
        type = "task",
        habitCount = 0,
    }) {
        this.id = id;
        this.name = name;
        this.startTime = startTime;
        this.endTime = endTime;
        this.isCompleted = isCompleted;
        this.completeTime = completeTime;
        this.note = note;
        this.isArchived = isArchived;
        this.isStared = isStared;
        this.type = type;
        this.habitCount = habitCount;
    }
}

module.exports = DDLItem;